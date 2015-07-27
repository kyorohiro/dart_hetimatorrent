library hetimatorrent.extra.torrentengine.ai.dht;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentai_basic.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import '../dht/knode.dart';

class TorrentEngineDHT extends TorrentAI {
  
  KNode _node = null;
  TorrentEngineDHT(HetiSocketBuilder socketBuilder) {
    _node = new KNode(socketBuilder);
  }

  Future start() {
    _node.start();
  }
  
  Future stop() {
    _node.stop();
  }

  @override
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    return new Future((){});
  }

  @override
  Future onRegistAI(TorrentClient client) {
    return new Future((){});
  }

  @override
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message) {
    return new Future((){});
  }

  @override
  Future onTick(TorrentClient client) {
    return new Future((){});
  }
}