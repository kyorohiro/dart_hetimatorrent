library hetimatorrent.torrent.ai;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';

import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';

abstract class TorrentAI {
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message);
}


class TorrentAIBasicDelivery extends TorrentAI {

  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    TorrentClientFront front = client.getPeerInfoFromId(info.id);
    if(message.id == TorrentMessage.SIGN_PIECE) {
      front.sendHandshake().then((_){
        //
      });
    }
  }

}