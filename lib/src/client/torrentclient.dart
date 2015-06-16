library hetimatorrent.torrent.trackerrserver;

import 'dart:core';
import 'dart:async';
import 'dart:typed_data' as type;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'trackerurl.dart';
import 'trackerpeermanager.dart';
import '../util/bencode.dart';
import 'trackerresponse.dart';
import 'trackerrequest.dart';

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
