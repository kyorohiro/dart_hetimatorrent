library hetimatorrent.torrent.client;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';
import 'torrentai.dart';
import 'torrentai_basic.dart';
import 'torrentclientmessage.dart';

import '../util/blockdata.dart';
import '../util/bitfield.dart';
import 'message/message.dart';
import '../file/torrentfile.dart';

class TorrentClient {
  HetimaServerSocket _server = null;
  HetimaSocketBuilder _builder = null;
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

  StreamController<TorrentClientMessage> messageStream = new StreamController.broadcast();
  Stream<TorrentClientMessage> get onReceiveEvent => messageStream.stream;

  StreamController<TorrentClientSignal> _signalStream = new StreamController.broadcast();
  Stream<TorrentClientSignal> get onReceiveSignal => _signalStream.stream;

  BlockData _targetBlock = null;
  BlockData get targetBlock => _targetBlock;

  TorrentAI _ai = null;
  bool _isStart = false;
  bool get isStart => _isStart;
  int tickSec = 6;

  TorrentClientPeerInfoList get rawPeerInfos => _peerInfos;
  List<int> _reseved = [0, 0, 0, 0, 0, 0, 0, 0];
  List<int> get reseved => new List.from(_reseved);


  bool _verbose = false;
  bool get verbose => _verbose;

  static Future<TorrentClient> create(HetimaSocketBuilder builder, List<int> peerId, TorrentFile file, HetimaData data,
      {TorrentAI ai: null,List<int>bitfield:null,List<int> reserved:null, verbose:false}) {
    return file.createInfoSha1().then((List<int> infoHash) {
      return new TorrentClient(builder, peerId, infoHash, file.info.pieces, file.info.piece_length, 
          file.info.files.dataSize, data, ai: ai,bitfield:bitfield,reserved:reserved, verbose:verbose);
    });
  }

  TorrentClient(HetimaSocketBuilder builder, List<int> peerId, List<int> infoHash, List<int> piece, 
                int pieceLength, int fileSize, HetimaData data, {TorrentAI ai: null, haveAllData: false,
                  List<int>bitfield:null,List<int> reserved:null, verbose:false}) {
    this._builder = builder;
    _peerInfos = new TorrentClientPeerInfoList();
    _infoHash.addAll(infoHash);
    _peerId.addAll(peerId);
    _targetBlock = new BlockData(data, new Bitfield(Bitfield.calcbitSize(piece.length),
        clearIsOne: haveAllData), pieceLength, fileSize);
    if(bitfield != null) {
       _targetBlock.rawHead.writeBytes(bitfield);
    }
    if (ai == null) {
      this.ai = new TorrentAIBasic();
    } else {
      this.ai = ai;
    }
    if(reserved == null) {
      _reseved = [0,0,0,0,0,0,0,0];
    } else {
      _reseved.clear();
      _reseved.addAll(reserved);
    }
    _verbose = verbose;
  }

  TorrentClientPeerInfo putTorrentPeerInfoFromTracker(String ip, int port) {
    TorrentClientPeerInfo ret = _peerInfos.putPeerInfoFormTracker(ip, port);
    TorrentClientSignal sig = new TorrentClientSignalWithPeerInfo(ret, TorrentClientSignal.ID_ADD_PEERINFO, 0, "add peer info");
    _sendSignal(this, ret, sig);
    return ret;
  }

  TorrentClientPeerInfo _putTorrentPeerInfoFromAccept(String ip, int port) {
    TorrentClientPeerInfo ret = _peerInfos.putPeerInfoFormAccept(ip, port);
    TorrentClientSignal sig = new TorrentClientSignalWithPeerInfo(ret, TorrentClientSignal.ID_ADD_PEERINFO, 0, "add peer info");
    _sendSignal(this, ret, sig);
    return ret;
  }

  Future startWithoutSocket(String localAddress, int localPort, [String globalIp = null, int globalPort = null]) {
    this._localAddress = localAddress;
    this._localPort = localPort;
    this.globalPort = globalPort;
    this.globalIp = globalIp;
    return new Future(() {
      _isStart = true;
      _tick();
      return {};
    });
  }

  Future onAccept(HetimaSocket socket) {
    return new Future(() {
      if(false == _isStart) {
        return null;
      }
      return socket.getSocketInfo().then((HetimaSocketInfo socketInfo) {
        log("accept: ${socketInfo.peerAddress}, ${socketInfo.peerPort}");
        TorrentClientPeerInfo info = _putTorrentPeerInfoFromAccept(socketInfo.peerAddress, socketInfo.peerPort);
        info.front = new TorrentClientFront(socket, socketInfo.peerAddress, socketInfo.peerPort, socket.buffer, this._targetBlock.bitSize, _infoHash, _peerId, _reseved);
        _internalOnReceive(info.front, info);
        info.front.startReceive();
        TorrentClientSignal sig = new TorrentClientSignalWithPeerInfo(info, TorrentClientSignal.ID_ACCEPT, 0, "accepted");
        _sendSignal(this, info, sig);
      });
    }).catchError((e) {
      socket.close();
    });
  }

  Future start(String localAddress, int localPort, [String globalIp = null, int globalPort = null]) {
    this._localAddress = localAddress;
    this._localPort = localPort;
    this.globalPort = globalPort;
    this.globalIp = globalIp;
    if (this.globalPort == null) {
      this.globalPort = localPort;
    }
    return _builder.startServer(localAddress, localPort).then((HetimaServerSocket serverSocket) {
      _server = serverSocket;
      _server.onAccept().listen((HetimaSocket socket) {
        onAccept(socket);
      });
      TorrentClientSignal sig = new TorrentClientSignal(TorrentClientSignal.ID_STARTED_CLIENT, 0, "started client");
      _sendSignal(this, null, sig);
      return new Future(() {
        _isStart = true;
        _tick();
        return {};
      });
    });
  }

  Future _tick() {
    return new Future.delayed(new Duration(seconds: tickSec)).then((_) {
      if (_isStart != true) {
        return {};
      }
      if (_ai != null) {
        _ai.onTick(this);
      }
      _tick();
    });
  }

  Future stop() {
    List<Future> w = [];
    Future f = null;
    for (TorrentClientPeerInfo s in this.peerInfos) {
      f = new Future(() {
        if (s.front != null && s.front.isClose == false) {
          return s.front.close();
        }
      }).catchError((e) {
        ;
      });
      w.add(f);
    }

    f = new Future(() {
      TorrentClientSignal sig = new TorrentClientSignal(TorrentClientSignal.ID_STOPPED_CLIENT, 0, "stopped client");
      _sendSignal(this, null, sig);
      if(_server != null) {
        return _server.close();
      }
    }).catchError((e) {
      ;
    });
    _isStart = false;
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
      //
      // cuurent implements duprecate connection do not permit
      if(info.front != null && info.front.isClose == false) {
        throw {};
      }
      if(false == _isStart) {
        throw {};
      }
      return TorrentClientFront.connect(_builder, info, this._targetBlock.bitSize, infoHash, peerId:peerId, reseved:_reseved).then((TorrentClientFront front) {
        info.front = front;
        _internalOnReceive(front, info);
        front.startReceive();
        _sendSignal(this, info, new TorrentClientSignalWithPeerInfo(info, TorrentClientSignal.ID_CONNECTED, 0, "connected"));
        return front;
      });
    });
  }

  void _sendSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal sig) {
    _signalStream.add(sig);
    _ai.onSignal(this, info, sig);
  }

  void _internalOnReceive(TorrentClientFront front, TorrentClientPeerInfo info) {
    front.onReceiveEvent.listen((TorrentMessage message) {
      messageStream.add(new TorrentClientMessage(info, message));
      if (message is MessagePiece) {
        MessagePiece piece = message;
        _targetBlock.writePartBlock(piece.content, piece.index, piece.begin, piece.content.length).then((WriteResult w) {
          if (_targetBlock.have(piece.index)) {
            _sendSignal(this, info, new TorrentClientSignal(TorrentClientSignal.ID_SET_PIECE, piece.index, "set piece : index:${piece.index}"));
          } else {
            _sendSignal(this, info, new TorrentClientSignal(TorrentClientSignal.ID_SET_PIECE_A_PART, piece.index, "set piece : index:${piece.index}"));            
          }
          if (_targetBlock.haveAll()) {
            _sendSignal(this, null, new TorrentClientSignal(TorrentClientSignal.ID_SET_PIECE_ALL, piece.index, "set piece all"));
          }
        });
      } else if (message is MessageHandshake) {
        //
        //
      }
      _ai.onReceive(this, info, message);
    });
    front.onReceiveSignal.listen((TorrentClientSignalWithFront signal) {
      switch (signal.id) {
        case TorrentClientSignal.ID_PIECE_RECEIVE:
          this._downloaded += signal.v;
          break;
        case TorrentClientSignal.ID_PIECE_SEND:
          this._uploaded += signal.v;
          break;
      }
      TorrentClientSignal sig = new TorrentClientSignalWithPeerInfo(info, signal.id, signal.reason, signal.toString());
      _sendSignal(this, info, sig);
    });
  }

  void set ai(TorrentAI v) {
    _ai = v;
  }
  TorrentAI get ai => _ai;
  
  log(String message) {
    if(_verbose) {
      print("**${message}");
    }
  }
}
