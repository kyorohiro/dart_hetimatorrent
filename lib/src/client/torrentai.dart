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
      if (message.id == TorrentMessage.SIGN_PIECE) {
        if (false == front.handshakeToMe) {
          return front.sendHandshake();
        }
      }
    });
  }
  
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message) {
    return new Future((){
      
    });
  }
}
