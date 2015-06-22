library hetimatorrent.torrent.client;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../util/peeridcreator.dart';
import '../message/message.dart';
import '../util/shufflelinkedlist.dart';

class TorrentClientFront {
  List<int> _peerId = [];
  List<int> _infoHash = [];

  EasyParser _parser = null;
  HetiSocket _socket = null;
  bool handshaked = false;

  String ip = "";
  int port = 0;
  int speed = 0; //per sec bytes
  int downloadedBytesFromMe = 0; // Me is Hetima
  int uploadedBytesToMe = 0; // Me is Hetima
  int chokedFromMe = 0; // Me is Hetima
  int chokedToMe = 0; // Me is Hetima

  static Future<TorrentClientFront> connect(HetiSocketBuilder _builder, TorrentClientPeerInfo info, List<int> infoHash, [List<int> peerId = null]) {
    return new Future(() {
      HetiSocket socket = _builder.createClient();
      return socket.connect(info.ip, info.port).then((HetiSocket socket) {
        return new TorrentClientFront(socket, info.ip, info.port, socket.buffer, infoHash, peerId);
      });
    });
  }

  TorrentClientFront(HetiSocket socket, String ip, int port, HetimaReader reader, List<int> infoHash, List<int> peerId) {
    if (peerId == null) {
      _peerId.addAll(PeerIdCreator.createPeerid("heti69"));
    } else {
      _peerId.addAll(peerId);
    }
    _infoHash.addAll(infoHash);
    _socket = socket;
    _parser = new EasyParser(reader);
    handshaked = false;
  }

  StreamController<TorrentMessage> stream = new StreamController();
  Stream<TorrentMessage> get onReceiveEvent => stream.stream;

  Future<TorrentMessage> parse() {
    if (handshaked == false) {
      return TorrentMessage.parseHandshake(_parser);
    } else {
      return TorrentMessage.parseHandshake(_parser);
    }
  }

  void startReceive() {
    a() {
      new Future(() {
        parse().then((TorrentMessage message) {
          stream.add(message);
          a();
        });
      }).catchError((e) {
        stream.addError(e);
      });
    }
    a();
  }

  Future sendHandshake() {
    MessageHandshake message = new MessageHandshake(MessageHandshake.ProtocolId, [0, 0, 0, 0, 0, 0, 0, 0], _infoHash, _peerId);
    return message.encode().then((List<int> v) {
      return _socket.send(v).then((HetiSendInfo info) {
        return {};
      });
    });
  }
}

class TorrentMessageInfo {
  TorrentMessage message;
  TorrentClientFront front;
  TorrentMessageInfo(TorrentClientFront front, TorrentMessage message) {
    this.message = message;
    this.front = front;
  }
}

class TorrentClient {
  HetiServerSocket _server = null;
  HetiSocketBuilder _builder = null;
  List<int> _peerId = [];
  List<int> _infoHash = [];
  String localAddress = "0.0.0.0";
  int port = 8080;

  List<HetiSocket> _managedSocketList = [];
  List<int> get peerId => new List.from(_peerId);
  List<int> get infoHash  => new List.from(_infoHash);
 
  TorrentClientPeerInfoList _peerInfos;
  List<TorrentClientPeerInfo> get peerInfos => _peerInfos.peerInfos.sequential;

  StreamController<TorrentMessageInfo> stream = new StreamController();
  Stream<TorrentMessageInfo> get onReceiveEvent => stream.stream;

  TorrentClient(HetiSocketBuilder builder, List<int> infoHash, List<int> peerId) {
    this._builder = builder;
    _peerInfos = new TorrentClientPeerInfoList();
    _infoHash.addAll(infoHash);
    _peerId.addAll(peerId);
  }

  TorrentClientPeerInfo putTorrentPeerInfo(String ip, int port, {peerId: ""}) {
    return _peerInfos.putFormTrackerPeerInfo(ip, port, peerId: peerId);
  }

  Future start() {
    return _builder.startServer(localAddress, port).then((HetiServerSocket serverSocket) {
      _server = serverSocket;
      _server.onAccept().listen((HetiSocket socket) {
        new Future(() {
          return socket.getSocketInfo().then((HetiSocketInfo socketInfo) {
            TorrentClientPeerInfo info = putTorrentPeerInfo(socketInfo.localAddress, socketInfo.localPort);
            info.front = new TorrentClientFront(socket, socketInfo.localAddress, socketInfo.localPort, socket.buffer, _infoHash, _peerId);
            info.front.onReceiveEvent.listen((TorrentMessage message) {
              stream.add(new TorrentMessageInfo(info.front, message));
            });
          });
        }).catchError((e) {
          socket.close();
        });
      });
      return {};
    });
  }

  TorrentClientPeerInfo getPeerInfoFromId(int id) {
    return _peerInfos.getPeerInfoFromId(id);
  }

  Future<TorrentClientFront> connect(HetiSocketBuilder _builder, TorrentClientPeerInfo info, List<int> infoHash, [List<int> peerId = null]) {
    return new Future(() {
      return TorrentClientFront.connect(_builder, info, infoHash, peerId).then((TorrentClientFront front) {
        front.onReceiveEvent.listen((TorrentMessage message) {
          stream.add(new TorrentMessageInfo(info.front, message));
        });
        return front;
      });
    });
  }

  Future stop() {
    _server.close();
    for (HetiSocket s in _managedSocketList) {
      s.close();
    }
    return new Future(() {
      return {};
    });
  }
}

class TorrentClientPeerInfoList {
  ShuffleLinkedList<TorrentClientPeerInfo> peerInfos;

  TorrentClientPeerInfoList() {
    peerInfos = new ShuffleLinkedList();
  }

  TorrentClientPeerInfo putFormTrackerPeerInfo(String ip, int port, {peerId: ""}) {
    for (int i = 0; i < peerInfos.length; i++) {
      TorrentClientPeerInfo info = peerInfos.getSequential(i);
      if (info.ip == ip || info.port == port) {
        // alredy added in peerinfo
        return info;
      }
    }
    TorrentClientPeerInfo info = new TorrentClientPeerInfo(ip, port, peerId: peerId);
    peerInfos.addLast(info);
    return info;
  }
  
  TorrentClientPeerInfo getPeerInfoFromId(int id) {
    for (int i = 0; i < peerInfos.length; i++) {
      TorrentClientPeerInfo info = peerInfos.getSequential(i);
      if (info.id == id) {
        return info;
      }
    }
    return null;
  }
}

class TorrentClientPeerInfo {
  static int nid = 0;
  int id = 0;
  String ip = "";
  int port = 0;
  TorrentClientFront front = null;

  TorrentClientPeerInfo(String ip, int port, {peerId: ""}) {
    this.ip = ip;
    this.port = port;
    this.id = ++nid;
  }

  /// per sec bytes
  int get speed {
    if (front == null) {
      return 0;
    } else {
      return front.speed;
    }
  }

  /// Me is Hetima
  int get downloadedBytesFromMe {
    if (front == null) {
      return 0;
    } else {
      return front.downloadedBytesFromMe;
    }
  }

  /// Me is Hetima
  int get uploadedBytesToMe {
    if (front == null) {
      return 0;
    } else {
      return front.uploadedBytesToMe;
    }
  }
  /// Me is Hetima
  int get chokedFromMe {
    if (front == null) {
      return 0;
    } else {
      return front.chokedFromMe;
    }
  }
  /// Me is Hetima
  int get chokedToMe {
    if (front == null) {
      return 0;
    } else {
      return front.chokedToMe;
    }
  }
}
