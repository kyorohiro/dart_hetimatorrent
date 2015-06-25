library hetimatorrent.torrent.ai;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';

import 'torrentclient.dart';
import 'torrentclientpeerinfo.dart';

abstract class TorrentAI {
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message);
}


class TorrentAIBasicDelivery extends TorrentAI {

  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    if(message.id == TorrentMessage.SIGN_PIECE) {
    }
  }

}