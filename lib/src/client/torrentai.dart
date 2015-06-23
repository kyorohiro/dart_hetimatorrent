library hetimatorrent.torrent.ai;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../util/peeridcreator.dart';
import '../message/message.dart';
import '../util/shufflelinkedlist.dart';

import 'torrentclientfront.dart';
import 'torrentclient.dart';
import 'torrentclientpeerinfo.dart';

class TorrentAI {

  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    if(message.id == TorrentMessage.SIGN_PIECE) {
    }
  }

}