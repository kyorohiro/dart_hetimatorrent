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
}

class TorrentAIBasic extends TorrentAI {
  bool _isStart = false;
  int _maxUnchoke = 8;
  int _maxConnect = 20;

  TorrentAIBasic({maxUnchoke: 8, maxConnect: 20}) {
    _maxUnchoke = maxUnchoke;
    _maxConnect = maxConnect;
  }

  Future onTick(TorrentClient client) {
    return new Future(() {
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
                cont.setRange(begin, end, result.buffer);
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
        case TorrentClientFrontSignal.ID_HANDSHAKED:
          info.front.sendBitfield(client.targetBlock.bitfield);
          break;
        case TorrentClientSignal.ID_ACCEPT:
        case TorrentClientSignal.ID_CONNECTED:
          break;
      }
    });
  }
}
