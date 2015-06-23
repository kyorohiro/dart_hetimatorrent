library hetimatorrent.torrent.client;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../util/peeridcreator.dart';
import '../message/message.dart';
import '../util/shufflelinkedlist.dart';

import 'torrentclientfront.dart';
import '../util/blockdata.dart';
import '../util/bitfield.dart';

import '../file/torrentfile.dart';

class TorrentMessageInfo {
  TorrentMessage message;
  TorrentClientFront get front => _info.front;
  TorrentClientPeerInfo get info => _info;
  TorrentClientPeerInfo _info;  
  
  TorrentMessageInfo(TorrentClientPeerInfo info, TorrentMessage message) {
    this.message = message;
    this._info = info;
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


  BlockData targetBlock = null;

  static Future<TorrentClient> create(HetiSocketBuilder builder, List<int> peerId, TorrentFile file, HetimaData data) {
    return file.createInfoSha1().then((List<int> infoHash) {
      return new TorrentClient(builder, infoHash, peerId, file.info.pieces, file.info.piece_length, file.info.files.dataSize, data);
    });
  }

  TorrentClient(HetiSocketBuilder builder, List<int> infoHash, List<int> peerId, List<int> piece, int pieceLength, int fileSize, HetimaData data) {
    this._builder = builder;
    _peerInfos = new TorrentClientPeerInfoList();
    _infoHash.addAll(infoHash);
    _peerId.addAll(peerId);
    targetBlock = new BlockData(data, new Bitfield(piece.length~/20), pieceLength, fileSize);
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
              stream.add(new TorrentMessageInfo(info, message));
            });
            info.front.startReceive();
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
          stream.add(new TorrentMessageInfo(info, message));
        });
        front.startReceive();
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
