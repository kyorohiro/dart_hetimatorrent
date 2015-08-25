library hetimatorrent.torrent.client.manager;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

import 'torrentclientmessage.dart';
import 'message/message.dart';
import 'torrentclient.dart';

/**
 * 
 */
class TorrentClientManager {
  String _localIp = "0.0.0.0";
  String globalIp = "0.0.0.0";
  int _localPort = 18080;
  int globalPort = 18080;

  bool _isStart = false;
  String get localIp => _localIp;
  int get localPort => _localPort;
  bool get isStart => _isStart;

  HetimaServerSocket _server = null;
  HetimaSocketBuilder _builder = null;

  StreamController<TorrentClientMessage> messageStream = new StreamController.broadcast();
  Stream<TorrentClientMessage> get onReceiveEvent => messageStream.stream;

  StreamController<TorrentClientSignal> _signalStream = new StreamController.broadcast();
  Stream<TorrentClientSignal> get onReceiveSignal => _signalStream.stream;

  List<TorrentClient> clients = [];

  bool _verbose = false;
  bool get verbose => _verbose;

  TorrentClientManager(HetimaSocketBuilder builder, {bool verbose: false}) {
    this._builder = builder;
    this._verbose = verbose;
  }

  void addTorrentClient(TorrentClient client) {
    if (null == getTorrentClient(client.infoHash)) {
      clients.add(client);
    }
  }

  /**
   * if infoHash args is unmanaged infohash, return null;
   */
  TorrentClient getTorrentClient(List<int> infoHash) {
    if (20 != infoHash.length) {
      return null;
    }
    for (TorrentClient client in clients) {
      bool isManagedInfoHash = true;
      for (int index = 0; index < infoHash.length; index++) {
        if (client.infoHash[index] != infoHash[index]) {
          isManagedInfoHash = false;
          break;
        }
      }
      if (isManagedInfoHash == true) {
        return client;
      }
    }
    return null;
  }

  Future start(String localAddress, int localPort, String globalIp, int globalPort) async {
    this._localIp = localAddress;
    this._localPort = localPort;
    this.globalPort = globalPort;
    this.globalIp = globalIp;
    if (this.globalPort == null) {
      this.globalPort = localPort;
    }

    HetimaServerSocket serverSocket = await _builder.startServer(localAddress, localPort);
    if (_isStart == true) {
      throw {"message": "already started"};
    }
    _server = serverSocket;
    _server.onAccept().listen((HetimaSocket socket) async {
      try {
        if (false == _isStart) {
          return null;
        }
        //
        HetimaSocketInfo socketInfo = await socket.getSocketInfo();
        log("accept: ${socketInfo.peerAddress}, ${socketInfo.peerPort}");
        MessageHandshake handshake = await TorrentMessage.parseHandshake(new EasyParser(socket.buffer));
        //
        TorrentClient client = getTorrentClient(handshake.infoHash);
        if (client == null) {
          // unmanaged infohash
          socket.close();
        }
        client.onAccept(socket);
      } catch (e) {
        socket.close();
        socket = null;
      }
    });
    TorrentClientSignal sig = new TorrentClientSignal(TorrentClientSignal.ID_STARTED_CLIENT, 0, "started client");
    _signalStream.add(sig);
    _isStart = true;
  }

  Future stop() async {
    if (_isStart == true) {
      _isStart = false;
      for (TorrentClient c in clients) {
        await c.stop();
      }
      _server.close();
    }
  }

  log(String message) {
    if (_verbose) {
      print("*+*${message}");
    }
  }
}
