library hetimatorrent.torrent.ai;

import 'dart:core';
import 'dart:async';
import 'message/message.dart';
import 'torrentclient.dart';
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
