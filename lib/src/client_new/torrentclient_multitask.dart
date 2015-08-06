library hetimatorrent.torrent.client;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

import '../client/torrentclientfront.dart';
import '../client/torrentclientpeerinfo.dart';
import '../client/torrentai.dart';
import '../client/torrentclientmessage.dart';

class TorrentClientWithMultiTask {
  String  _localIp = "0.0.0.0";
  String _globalIp = "0.0.0.0";
  int _localPort = 18080;
  int _globalPort = 18080;
  
  bool _isStart = false;
  String get localIp => _localIp;
  String get globalIp => _globalIp;
  int get localPort => _localPort;
  int get globalPort => _globalPort;
  bool get isStart => _isStart;

  HetiServerSocket _server = null;
  HetiSocketBuilder _builder = null;

  StreamController<TorrentClientMessage> messageStream = new StreamController.broadcast();
  Stream<TorrentClientMessage> get onReceiveEvent => messageStream.stream;

  StreamController<TorrentClientSignal> _signalStream = new StreamController.broadcast();
  Stream<TorrentClientSignal> get onReceiveSignal => _signalStream.stream;

  TorrentClientWithMultiTask(HetiSocketBuilder builder) {
    this._builder = builder;
  }
  
  Future start(String localAddress, int localPort, [String globalIp = null, int globalPort = null]) {
    this._localIp = localAddress;
    this._localPort = localPort;
    this._globalPort = globalPort;
    this._globalIp = globalIp;
    if (this._globalPort == null) {
      this._globalPort = localPort;
    }

    return _builder.startServer(localAddress, localPort).then((HetiServerSocket serverSocket) {
      _server = serverSocket;
      _server.onAccept().listen((HetiSocket socket) {
        new Future(() {
          if (false == _isStart) {
            return null;
          }
          return socket.getSocketInfo().then((HetiSocketInfo socketInfo) {
            print("accept: ${socketInfo.peerAddress}, ${socketInfo.peerPort}");
          });
        }).catchError((e) {
          socket.close();
          socket = null;
        });
      });
      TorrentClientSignal sig = new TorrentClientSignal(TorrentClientSignal.ID_STARTED_CLIENT, 0, "started client");
      _signalStream.add(sig);
    });
  }

  
  Future stop() {
    
  }

}
