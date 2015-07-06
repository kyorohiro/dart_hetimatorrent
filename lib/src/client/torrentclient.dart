library hetimatorrent.torrent.client;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';
import 'torrentai.dart';
import 'torrentclientmessage.dart';

import '../util/blockdata.dart';
import '../util/bitfield.dart';

import '../message/message.dart';

import '../file/torrentfile.dart';

class TorrentClient {
  HetiServerSocket _server = null;
  HetiSocketBuilder _builder = null;
  List<int> _peerId = [];
  List<int> _infoHash = [];
  String _localAddress = "0.0.0.0";
  int _localPort = 8080;

  String get localAddress => _localAddress;
  int get localPort => _localPort;
  int globalPort = 8080;
  String globalIp = "0.0.0.0";

  List<int> get peerId => new List.from(_peerId);
  List<int> get infoHash => new List.from(_infoHash);

  int _downloaded = 0;
  int _uploaded = 0;
  
  int get downloaded => _downloaded;
  int get uploaded => _uploaded;
  TorrentClientPeerInfoList _peerInfos;
  List<TorrentClientPeerInfo> get peerInfos => _peerInfos.peerInfos.sequential;

  StreamController<TorrentClientMessage> messageStream = new StreamController();
  Stream<TorrentClientMessage> get onReceiveEvent => messageStream.stream;

  StreamController<TorrentClientSignal> _signalStream = new StreamController.broadcast();
  Stream<TorrentClientSignal> get onReceiveSignal => _signalStream.stream;

  BlockData _targetBlock = null;
  BlockData get targetBlock => _targetBlock;

  TorrentAI _ai = null;
  bool _isStart = false;
  bool get isStart => _isStart;

  static Future<TorrentClient> create(HetiSocketBuilder builder, List<int> peerId, TorrentFile file, HetimaData data, {TorrentAI ai: null}) {
    return file.createInfoSha1().then((List<int> infoHash) {
      return new TorrentClient(builder, peerId, infoHash, file.info.pieces, file.info.piece_length, file.info.files.dataSize, data, ai: ai);
    });
  }

  TorrentClient(HetiSocketBuilder builder, List<int> peerId, List<int> infoHash, List<int> piece, int pieceLength, int fileSize, HetimaData data, {TorrentAI ai: null, haveAllData: false}) {
    this._builder = builder;
    _peerInfos = new TorrentClientPeerInfoList();
    _infoHash.addAll(infoHash);
    _peerId.addAll(peerId);
    _targetBlock = new BlockData(data, new Bitfield(piece.length ~/ 20, clearIsOne: haveAllData), pieceLength, fileSize);
    if (ai == null) {
      this.ai = new TorrentAIBasic();
    } else {
      this.ai = ai;
    }
  }

  TorrentClientPeerInfo putTorrentPeerInfo(String ip, int port, {peerId: ""}) {
    return _peerInfos.putFormTrackerPeerInfo(ip, port, peerId: peerId);
  }

  Future start(String localAddress, int localPort, [String globalIp = null, int globalPort = null]) {
    this._localAddress = localAddress;
    this._localPort = localPort;
    this.globalPort = globalPort;
    this.globalIp = globalIp;
    if (this.globalPort == null) {
      this.globalPort = localPort;
    }
    return _builder.startServer(localAddress, localPort).then((HetiServerSocket serverSocket) {
      _server = serverSocket;
      _server.onAccept().listen((HetiSocket socket) {
        new Future(() {
          return socket.getSocketInfo().then((HetiSocketInfo socketInfo) {
            TorrentClientPeerInfo info = putTorrentPeerInfo(socketInfo.peerAddress, socketInfo.peerPort);
            info.front = new TorrentClientFront(socket, socketInfo.peerAddress, socketInfo.peerPort, socket.buffer, this._targetBlock.bitSize, _infoHash, _peerId);
            _internalOnReceive(info.front, info);
            info.front.startReceive();
            _isStart = true;
            _signalStream.add(new TorrentClientSignalWithPeerInfo(info, TorrentClientSignal.ID_ACCEPT, 0, "accepted"));
          });
        }).catchError((e) {
          socket.close();
        });
      });
      _signalStream.add(new TorrentClientSignal(TorrentClientSignal.ID_STARTED_CLIENT, 0, "started client"));
      return {};
    });
  }

  Future stop() {
    List<Future> w = [];
    Future f = null;
    for (TorrentClientPeerInfo s in this.peerInfos) {
      f = new Future(() {
        if (s.front != null && s.front.isClose != false) {
          return s.front.close();
        }
      }).catchError((e) {
        ;
      });
      w.add(f);
    }

    f = new Future(() {
      _isStart = false;
      _signalStream.add(new TorrentClientSignal(TorrentClientSignal.ID_STOPPED_CLIENT, 0, "stopped client"));
      return _server.close();
    }).catchError((e) {
      ;
    });

    w.add(f);
    return Future.wait(w);
  }

  List<TorrentClientPeerInfo> getPeerInfoFromXx(Function filter) {
    List<TorrentClientPeerInfo> ret = [];
    for (TorrentClientPeerInfo info in this.peerInfos) {
      if (true == filter(info)) {
        ret.add(info);
      }
    }
    return ret;
  }

  TorrentClientPeerInfo getPeerInfoFromId(int id) {
    return _peerInfos.getPeerInfoFromId(id);
  }

  Future<TorrentClientFront> connect(TorrentClientPeerInfo info) {
    //, List<int> infoHash, [List<int> peerId = null]) {
    return new Future(() {
      return TorrentClientFront.connect(_builder, info, this._targetBlock.bitSize, infoHash, peerId).then((TorrentClientFront front) {
        info.front = front;
        _internalOnReceive(front, info);
        front.startReceive();
        _signalStream.add(new TorrentClientSignalWithPeerInfo(info, TorrentClientSignal.ID_CONNECTED, 0, "connected"));
        return front;
      });
    });
  }

  void _internalOnReceive(TorrentClientFront front, TorrentClientPeerInfo info) {
    front.onReceiveEvent.listen((TorrentMessage message) {
      messageStream.add(new TorrentClientMessage(info, message));
      if (message is MessagePiece) {
        _onPieceMessage(message);
      }
      _ai.onReceive(this, info, message);
    });
    front.onReceiveSignal.listen((TorrentClientFrontSignal signal) {
      switch(signal.id) {
        case TorrentClientFrontSignal.ID_PIECE_RECEIVE:
          this._downloaded = signal.v;
          break;
        case TorrentClientFrontSignal.ID_PIECE_SEND:
          this._uploaded = signal.v;
          break;
      }
      TorrentClientSignal sig = new TorrentClientSignalWithPeerInfo(info, signal.id, signal.reason, signal.toString());
      _signalStream.add(sig);
      _ai.onSignal(this, info, sig);
    });
  }

  void _onPieceMessage(MessagePiece piece) {
    _targetBlock.writePartBlock(piece.content, piece.index, piece.begin, piece.content.length).then((WriteResult w) {
      if (_targetBlock.have(piece.index)) {
        _signalStream.add(new TorrentClientSignal(TorrentClientSignal.ID_SET_PIECE, piece.index, "set piece : index:${piece.index}"));
      }
      if (_targetBlock.haveAll()) {
        _signalStream.add(new TorrentClientSignal(TorrentClientSignal.ID_SET_PIECE_ALL, piece.index, "set piece all"));
      }
    });
  }

  void set ai(TorrentAI v) {
    _ai = v;
  }
  TorrentAI get ai => _ai;
}
