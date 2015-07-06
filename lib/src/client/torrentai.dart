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
  Future start();
  Future stop();
}

class TorrenAIEmpty extends TorrentAI {
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    return new Future(() {
      print("Empty AI receive : ${message.id}");
    });
  }
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message) {
    return new Future(() {
      print("Empty AI signal : ${message.id}");
    });
  }
  Future start() {
    return new Future(() {});
  }
  Future stop() {
    return new Future(() {});
  }
}

class TorrentAIBasic extends TorrentAI {
  bool _isStart = false;
  int _maxUnchoke = 8;
  int _maxConnect = 20;
  int _tickTime = 5;

  TorrentAIBasic({maxUnchoke: 8, maxConnect: 20, tickTime: 5}) {
    _maxUnchoke = maxUnchoke;
    _maxConnect = maxConnect;
  }

  Future start() {
    t() {
      return new Future.delayed(new Duration(seconds: _tickTime)).then((_) {
        onTick();
        if (_isStart == true) {
          t();
        }
      });
    }
    return new Future(() {
      if (_isStart != true) {
        _isStart = true;
        t();
      }
    });
  }

  Future stop() {
    return new Future(() {
      _isStart = false;
    });
  }

  Future onTick() {
    return new Future(() {
      _isStart = false;
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
      switch(signal.id) {
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
