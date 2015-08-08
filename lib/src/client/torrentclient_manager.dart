library hetimatorrent.torrent.client.manager;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';
import 'torrentai.dart';
import 'torrentclientmessage.dart';
import 'message/message.dart';
import 'torrentclient.dart';

class TorrentClientManager {
  String _localIp = "0.0.0.0";
  String globalIp = "0.0.0.0";
  int _localPort = 18080;
  int globalPort = 18080;

  bool _isStart = false;
  String get localIp => _localIp;
  int get localPort => _localPort;
  bool get isStart => _isStart;

  HetiServerSocket _server = null;
  HetiSocketBuilder _builder = null;

  StreamController<TorrentClientMessage> messageStream = new StreamController.broadcast();
  Stream<TorrentClientMessage> get onReceiveEvent => messageStream.stream;

  StreamController<TorrentClientSignal> _signalStream = new StreamController.broadcast();
  Stream<TorrentClientSignal> get onReceiveSignal => _signalStream.stream;

//  List<int> _peerId = [];
//  List<int> _reserved = [];

  List<TorrentClient> clients = [];

  TorrentClientManager(HetiSocketBuilder builder) {
    this._builder = builder;
//    _peerId.addAll(peerId);
//    _reserved.addAll(reserved);
  }

  void addTorrentClient(TorrentClient client) {
    if (null == getTorrentClient(client.infoHash)) {
      clients.add(client);
    }
  }

  TorrentClient getTorrentClient(List<int> infoHash) {
    for (TorrentClient c in clients) {
      bool isOk = true;
      if (c.infoHash.length != infoHash.length) {
        continue;
      }
      for (int j = 0; j < infoHash.length; j++) {
        if (c.infoHash[j] != infoHash[j]) {
          isOk = false;
          break;
        }
      }
      if(isOk == true) {
        return c;
      }
    }
    return null;
  }

  Future start(String localAddress, int localPort, String globalIp, int globalPort) {
    this._localIp = localAddress;
    this._localPort = localPort;
    this.globalPort = globalPort;
    this.globalIp = globalIp;
    if (this.globalPort == null) {
      this.globalPort = localPort;
    }

    return _builder.startServer(localAddress, localPort).then((HetiServerSocket serverSocket) {
      if (_isStart == true) {
        throw {"message": "already started"};
      }
      _server = serverSocket;
      _server.onAccept().listen((HetiSocket socket) {
        new Future(() {
          if (false == _isStart) {
            return null;
          }
          return socket.getSocketInfo().then((HetiSocketInfo socketInfo) {
            print("accept: ${socketInfo.peerAddress}, ${socketInfo.peerPort}");
            return TorrentMessage.parseHandshake(new EasyParser(socket.buffer)).then((TorrentMessage message) {
              //
              MessageHandshake handshake = message;
              TorrentClient client = getTorrentClient(handshake.infoHash);
              if (client == null) {
                // unmanaged infohash
                socket.close();
              }
              client.onAccept(socket);
            });
          });
        }).catchError((e) {
          socket.close();
          socket = null;
        });
      });
      TorrentClientSignal sig = new TorrentClientSignal(TorrentClientSignal.ID_STARTED_CLIENT, 0, "started client");
      _signalStream.add(sig);
      _isStart = true;
    });
  }

  Future stop() {
    return new Future(() {
      if (_isStart == true) {
        _isStart = false;
        List<Future> f = [];
        for (TorrentClient c in clients) {
          f.add(c.stop());
        }
        _server.close();

        return Future.wait(f);
      }
    });
  }
}
