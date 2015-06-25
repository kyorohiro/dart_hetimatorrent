library hetimatorrent.torrent.ai;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';

import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';

abstract class TorrentAI {
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message);
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message);
}

class TorrentAIBasicDelivery extends TorrentAI {
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info,TorrentMessage message) {
    return new Future(() {
      TorrentClientFront front = info.front;
      if (message.id == TorrentMessage.DUMMY_SIGN_SHAKEHAND) {
        MessageHandshake handshakeMessage = message;
        if (true == front.handshakeToMe) {
          return true;
        }
        if(handshakeMessage.peerId == client.peerId) {
          front.close();
          info.amI = true;
        }
        return front.sendHandshake();
      }
    });
  }
  
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal signal) {
    return new Future((){
      if(signal.signal == TorrentClientFrontSignal.HANDSHAKED) {
        info.front.sendBitfield(client.targetBlock.bitfield);
      }
    });
  }
}
