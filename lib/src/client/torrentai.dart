library hetimatorrent.torrent.ai;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';
import 'package:hetimacore/hetimacore.dart';
import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';
import 'torrentclientmessage.dart';
import 'torrentaichoke.dart';

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
