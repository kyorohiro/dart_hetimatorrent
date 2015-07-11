library hetimatorrent.torrent.ai;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';
import 'package:hetimacore/hetimacore.dart';
import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';
import 'torrentclientmessage.dart';

abstract class TorrentAI {
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message);
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message);
  Future onTick(TorrentClient client);
  Future onRegistAI(TorrentClient client);
}

class TorrenAIEmpty extends TorrentAI {
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    return new Future(() {
      print("Empty AI receive : ${message.id} ${client.peerId}");
    });
  }

  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message) {
    return new Future(() {
      print("Empty AI signal : ${message.id} ${client.peerId}");
    });
  }

  Future onTick(TorrentClient client) {
    return new Future(() {
      print("Empty AI signal : ${client.peerId}");
    });
  }
  Future onRegistAI(TorrentClient client) {
    return new Future(() {
      print("Empty AI regist : ${client.peerId}");
    });
  }
}

class TorrentAIBasic extends TorrentAI {
  int _maxUnchoke = 8;
  int _maxConnect = 20;

  TorrentAIBasic({maxUnchoke: 8, maxConnect: 20}) {
    _maxUnchoke = maxUnchoke;
    _maxConnect = maxConnect;
  }

  Future onRegistAI(TorrentClient client) {
    return new Future(() {
      print("Basic AI regist : ${client.peerId}");
    });
  }

  Future onTick(TorrentClient client) {
    return new Future(() {
      _chokeTest(client);
    });
  }

  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    return new Future(() {
      TorrentClientFront front = info.front;
      switch (message.id) {
        case TorrentMessage.DUMMY_SIGN_SHAKEHAND:
          {
            if (true == front.handshakeFromMe || info.amI == true) {
              return null;
            } else {
              return front.sendHandshake();
            }
          }
          break;
        case TorrentMessage.SIGN_REQUEST:
          {
            if (info.front.chokedFromMe == TorrentClientFront.STATE_ON) {
              print("wearn ; already choked ${info.id}");
              break;
            }

            MessageRequest requestMessage = message;
            int index = requestMessage.index;
            int begin = requestMessage.begin;
            int len = requestMessage.length;

            if (false == client.targetBlock.have(index)) {
              //
              //
              front.close();
              return null;
            } else {
              return client.targetBlock.readBlock(index).then((ReadResult result) {
                int end = begin + len;
                List cont = new List.filled(len, 0);
                if (len > result.buffer.length) {
                  end = result.buffer.length;
                }
//                cont.setRange(begin, end, result.buffer);
                cont.setRange(0, len, result.buffer,begin);
                return front.sendPiece(index, begin, cont).then((_) {
                  ;
                });
              });
            }
          }
          break;
        case TorrentMessage.SIGN_BITFIELD:
          {
            break;
          }
      }
    });
  }

  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal signal) {
    return new Future(() {
      switch (signal.id) {
        case TorrentClientSignal.ID_HANDSHAKED:
          info.front.sendBitfield(client.targetBlock.bitfield);
          break;
        case TorrentClientSignal.ID_ACCEPT:
        case TorrentClientSignal.ID_CONNECTED:
          break;
        case TorrentClientSignal.ID_ADD_PEERINFO:
          if (info.front == null || info.front.isClose == true) {
            List<TorrentClientPeerInfo> connects = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
              if (info.front == null || info.front.isClose == true) {
                return true;
              }
            });
            if (connects.length < _maxConnect && (info.front == null || info.front.amI == false)) {
              return client.connect(info).then((TorrentClientFront f) {
                return f.sendHandshake();
              }).catchError((e) {
                try {
                  if(info.front != null) {
                    info.front.close();
                  }
                } catch (e) {
                  ;
                }
              });
            }
          }
          break;
      }
    });
  }

  void _chokeTest(TorrentClient client) {
    List<TorrentClientPeerInfo> unchokeInterestedPeer = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      if (info.front != null && info.front.isClose == false && info.front.interestedToMe == TorrentClientFront.STATE_ON && info.front.chokedFromMe == TorrentClientFront.STATE_ON) {
        return true;
      }
      return false;
    });

    List<TorrentClientPeerInfo> newPeer = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      if (info.front != null && info.front.isClose == false && info.front.chokedFromMe == TorrentClientFront.STATE_NONE) {
        return true;
      }
      return false;
    });

    List<TorrentClientPeerInfo> chokedInterestPeer = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      if (info.front != null && info.front.isClose == false && info.front.chokedFromMe == TorrentClientFront.STATE_OFF) {
        return true;
      }
      return false;
    });

    List<TorrentClientPeerInfo> nextUnchoke = [];
    nextUnchoke.addAll(newPeer);
    nextUnchoke.addAll(chokedInterestPeer);

    //
    //
    // 2 peer change
    unchokeInterestedPeer.shuffle();
    if (unchokeInterestedPeer.length > (_maxUnchoke - 2)) {
      unchokeInterestedPeer.sort((TorrentClientPeerInfo x, TorrentClientPeerInfo y) {
        return x.front.uploadSpeedFromUnchokeFromMe - y.front.uploadSpeedFromUnchokeFromMe;
      });
      unchokeInterestedPeer.removeLast().front.sendChoke();
      if (unchokeInterestedPeer.length < (_maxUnchoke - 2)) {
        unchokeInterestedPeer.removeLast().front.sendChoke();
      }
    }

    //
    // add include peer
    //
    int unchokeNum = _maxUnchoke - unchokeInterestedPeer.length;
    nextUnchoke.shuffle();
    int numOfSendedUnchoke = 0;

    // first intersted peer
    for (int i = 0; i < unchokeNum && 0 < nextUnchoke.length; i++) {
      TorrentClientPeerInfo info = nextUnchoke.removeLast();
      if (info.front.interestedToMe == TorrentClientFront.STATE_ON || info.front.interestedToMe == TorrentClientFront.STATE_NONE) {
        info.front.sendUnchoke();
        numOfSendedUnchoke++;
      }
    }

    // secound notinterested peer
    for (int i = 0; i < (_maxUnchoke - numOfSendedUnchoke) && 0 < nextUnchoke.length; i++) {
      TorrentClientPeerInfo info = nextUnchoke.removeLast();
      if (info.front.amI == false && info.front.interestedToMe == TorrentClientFront.STATE_OFF) {
        info.front.sendUnchoke();
      }
    }

    //
    // send unchoke
    for (TorrentClientPeerInfo info in nextUnchoke) {
      if (info.chokedFromMe == false) {
        info.front.sendChoke();
      }
    }
  }
}
