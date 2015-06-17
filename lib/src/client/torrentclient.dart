library hetimatorrent.torrent.trackerrserver;

import 'dart:core';
import 'dart:async';
import 'dart:typed_data' as type;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../util/bencode.dart';
import '../util/peeridcreator.dart';
import '../message/torrentmessage.dart';
import '../message/messagehandshake.dart';

class TorrentClientManager {
  List<int> _peerId = [];

  EasyParser _parser = null;

  TorrentClientManager(HetimaReader reader, [List<int> peerId=null]) {
    if(peerId == null) {
      _peerId.addAll(PeerIdCreator.createPeerid("heti69"));
    } else {
      _peerId.addAll(peerId);      
    }
    _parser = new EasyParser(reader);
  }


  StreamController<TorrentMessage> stream = new StreamController();

  Stream<TorrentMessage> get onReceiveEvent => stream.stream;

  parser() {
    MessageHandshake.decode(_parser).then((MessageHandshake shakeEvent) {
      stream.add(shakeEvent);
    }).catchError((e){
      
    });
  }
}


class TorrentClient {
  
  HetiServerSocket _server = null;
  HetiSocketBuilder _builder = null;
  
  String localAddress = "0.0.0.0";
  int port = 8080;

  List<HetiSocket> _managedSocketList = [];

  TorrentClient(HetiSocketBuilder builder) {
    this._builder = builder;
  }

  Future start() {
    return _builder.startServer(localAddress, port).then((HetiServerSocket serverSocket) {
      _server = serverSocket;
      _server.onAccept().listen((HetiSocket socket) {
        return null;
      });
    });
  }

  Future stop() {
    _server.close();
    for(HetiSocket s in _managedSocketList) {
      s.close();
    }
    return null;
  }
}
