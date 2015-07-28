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
  int _dhtPort = 18080;
  int get dhtPort => _dhtPort;

  TorrentEngineDHT(HetiSocketBuilder socketBuilder, int dhtPort) {
    _node = new KNode(socketBuilder);
    this._dhtPort = dhtPort;
  }

  Future start() {
    return new Future(() {
      _node.start();
    });
  }

  Future stop() {
    return new Future(() {
      _node.stop();
    });
  }

  @override
  Future onRegistAI(TorrentClient client) {
    return new Future(() {
      List<int> reserved = client.reseved;
      reserved[7] |= 0x01;
      client.reseved = reserved;
    });
  }

  @override
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    return new Future(() {
      if (message.id == TorrentMessage.SIGN_PORT) {
        info.front.sendPort(_dhtPort).catchError((e){
          print("wean : failed to sendPort");
        });
      }
    });
  }

  @override
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message) {
    return new Future(() {});
  }

  @override
  Future onTick(TorrentClient client) {
    return new Future(() {});
  }
}
