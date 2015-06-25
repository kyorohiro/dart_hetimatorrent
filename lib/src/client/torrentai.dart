library hetimatorrent.torrent.ai;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';
import 'package:hetimacore/hetimacore.dart';
import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';

abstract class TorrentAI {
  Future onReceive(
      TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message);
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info,
      TorrentClientSignal message);
}

class TorrenAIEmpty extends TorrentAI {
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    return new Future((){
      ;
    });
  }
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message) {
    return new Future((){
      ;
    });
  }
}

class TorrentAIBasic extends TorrentAI {
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
              return client.targetBlock.read(index).then((ReadResult result) {
                int end = begin+len;
                List cont = new List.filled(len, 0);
                if(len > result.buffer.length) {
                  end = result.buffer.length;
                }
                cont.setRange(begin, end, result.buffer);
                return front
                    .sendPiece(index, begin, cont)
                    .then((_) {
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

  Future onSignal(TorrentClient client, TorrentClientPeerInfo info,
      TorrentClientSignal signal) {
    return new Future(() {
      if (signal.signal.id == TorrentClientFrontSignal.ID_HANDSHAKED) {
        info.front.sendBitfield(client.targetBlock.bitfield);
      }
    });
  }
}
