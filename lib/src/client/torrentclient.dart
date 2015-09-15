library hetimatorrent.torrent.client;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';
import 'torrentclient_peerinfos.dart';
import 'torrentai.dart';
import 'torrentai_basic.dart';
import 'torrentclient_message.dart';

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
  TorrentClientPeerInfos _peerInfos;
//  List<TorrentClientPeerInfo> get peerInfos => _peerInfos.rawpeerInfos.sequential;
  List<TorrentClientPeerInfo> get peerInfos => _peerInfos.rawpeerInfos;

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

  TorrentClientPeerInfos get rawPeerInfos => _peerInfos;
  List<int> _reseved = [0, 0, 0, 0, 0, 0, 0, 0];
  List<int> get reseved => new List.from(_reseved);

  bool _verbose = false;
  bool get verbose => _verbose;

  static Future<TorrentClient> create(HetimaSocketBuilder builder, List<int> peerId, TorrentFile file, HetimaData data,
      {TorrentAI ai: null, List<int> bitfield: null, List<int> reserved: null, verbose: false}) async {
    List<int> infoHash = await file.createInfoSha1();
    return new TorrentClient(builder, peerId, infoHash, file.info.pieces, file.info.piece_length, file.info.files.dataSize, data, ai: ai, bitfield: bitfield, reserved: reserved, verbose: verbose);
  }

  TorrentClient(HetimaSocketBuilder builder, List<int> peerId, List<int> infoHash, List<int> piece, int pieceLength, int fileSize, HetimaData data,
      {TorrentAI ai: null, haveAllData: false, List<int> bitfield: null, List<int> reserved: null, verbose: false}) {
    _verbose = verbose;
    _builder = builder;
    _peerInfos = new TorrentClientPeerInfos();
    _infoHash.addAll(infoHash);
    _peerId.addAll(peerId);
    _targetBlock = new BlockData(data, null, pieceLength, fileSize, clearIsOne: haveAllData);

    this.ai = (ai == null ? new TorrentAIBasic() : ai);
    if (bitfield != null) {
      _targetBlock.rawHead.writeBytes(bitfield);
    }
    if (reserved != null) {
      _reseved.clear();
      _reseved.addAll(reserved);
    }
  }

  TorrentClientPeerInfo putTorrentPeerInfoFromTracker(String ip, int port) {
    TorrentClientPeerInfo ret = _peerInfos.putPeerInfoFromAddress(ip, acceptablePort:port);
    TorrentClientSignal sig = new TorrentClientSignalWithPeerInfo(ret, TorrentClientSignal.ID_ADD_PEERINFO, 0, "add peer info");
    _sendSignal(this, ret, sig);
    return ret;
  }

  TorrentClientPeerInfo _putTorrentPeerInfoFromAccept(String ip, int port) {
    TorrentClientPeerInfo ret = _peerInfos.putPeerInfoFromAddress(ip);
    TorrentClientSignal sig = new TorrentClientSignalWithPeerInfo(ret, TorrentClientSignal.ID_ADD_PEERINFO, 0, "add peer info");
    _sendSignal(this, ret, sig);
    return ret;
  }

  Future startWithoutStartingServer(String localAddress, int localPort, [String globalIp = null, int globalPort = null]) async {
    this._localAddress = localAddress;
    this._localPort = localPort;
    this.globalPort = globalPort;
    this.globalIp = globalIp;
    _isStart = true;
    _startIntervalTimer();
    return {};
  }

  Future onAccept(HetimaSocket socket) async {
    try {
      if (false == _isStart) {
        return null;
      }
      HetimaSocketInfo socketInfo = await socket.getSocketInfo();
      log("accept: ${socketInfo.peerAddress}, ${socketInfo.peerPort}");
      TorrentClientPeerInfo info = _putTorrentPeerInfoFromAccept(socketInfo.peerAddress, socketInfo.peerPort);
      info.front = new TorrentClientFront(socket, socketInfo.peerAddress, socketInfo.peerPort, socket.buffer, this._targetBlock.bitSize, _infoHash, _peerId, _reseved, verbose: _verbose);
      _internalOnReceive(info.front, info);
      info.front.startReceive();
      TorrentClientSignal sig = new TorrentClientSignalWithPeerInfo(info, TorrentClientSignal.ID_ACCEPT, 0, "accepted");
      _sendSignal(this, info, sig);
    } catch (e) {
      socket.close();
    }
  }

  Future start(String localAddress, int localPort, [String globalIp = null, int globalPort = null]) async {
    this._localAddress = localAddress;
    this._localPort = localPort;
    this.globalPort = globalPort;
    this.globalIp = globalIp;
    if (this.globalPort == null) {
      this.globalPort = localPort;
    }
    HetimaServerSocket serverSocket = await _builder.startServer(localAddress, localPort, mode:HetimaSocketBuilder.BUFFER_ONLY);
    _server = serverSocket;
    _server.onAccept().listen((HetimaSocket socket) {
      onAccept(socket);
    });

    _isStart = true;
    _startIntervalTimer();

    TorrentClientSignal sig = new TorrentClientSignal(TorrentClientSignal.ID_STARTED_CLIENT, 0, "started client");
    _sendSignal(this, null, sig);
  }

  bool _intervalTimerIsStarted = false;
  _startIntervalTimer() async {
    if (_intervalTimerIsStarted) {
      return;
    }
    _intervalTimerIsStarted = true;
    while (_isStart) {
      try {
        await new Future.delayed(new Duration(seconds: tickSec));
        if (_ai != null && _isStart == true) {
          _ai.onTick(this);
        }
      } catch (e) {}
    }
    _intervalTimerIsStarted = false;
  }

  Future stop() async {
    for (TorrentClientPeerInfo s in this.peerInfos) {
      try {
        if (s.front != null && s.front.isClose == false) {
          await s.front.close();
        }
      } catch (e) {}
    }

    try {
      if (_server != null) {
        await _server.close();
      }

      await clearIfIsEnd();
      TorrentClientSignal sig = new TorrentClientSignal(TorrentClientSignal.ID_STOPPED_CLIENT, 0, "stopped client");
      _sendSignal(this, null, sig);
    } catch (e) {}

    _isStart = false;
    return {};
  }

  clearIfIsEnd() async {
    await _peerInfos.clearIfIsEnd();
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

  Future<TorrentClientFront> connect(TorrentClientPeerInfo info) async {
    if (false == _isStart || info.front != null && info.front.isClose == false) {
      throw {};
    }
    info.front = await TorrentClientFront.connect(_builder, info, this._targetBlock.bitSize, infoHash, peerId: peerId, reseved: _reseved, verbose: _verbose);
    _internalOnReceive(info.front, info);
    info.front.startReceive();
    _sendSignal(this, info, new TorrentClientSignalWithPeerInfo(info, TorrentClientSignal.ID_CONNECTED, 0, "connected"));
    return info.front;
  }

  void _sendSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal sig) {
    _signalStream.add(sig);
    _ai.onSignal(this, info, sig);
  }

  void _internalOnReceive(TorrentClientFront front, TorrentClientPeerInfo info) {
    front.onReceiveEvent.listen((TorrentMessage message) async {
      messageStream.add(new TorrentClientMessage(info, message));
      if (message is TMessagePiece) {
        TMessagePiece piece = message;
        try {
          await _targetBlock.writePartBlock(piece.content, piece.index, piece.begin, piece.content.length);
          //
          //
          if (_targetBlock.have(piece.index)) {
            _sendSignal(this, info, new TorrentClientSignal(TorrentClientSignal.ID_SET_PIECE, piece.index, "set piece : index:${piece.index}"));
          } else {
            _sendSignal(this, info, new TorrentClientSignal(TorrentClientSignal.ID_SET_PIECE_A_PART, piece.index, "set piece : index:${piece.index}"));
          }
          if (_targetBlock.haveAll()) {
            _sendSignal(this, null, new TorrentClientSignal(TorrentClientSignal.ID_SET_PIECE_ALL, piece.index, "set piece all"));
          }
        } catch (e) {
          print("####ERROR ${e}");
        }
      }
      _ai.onReceive(this, info, message);
    });
    front.onReceiveSignal.listen((TorrentClientSignalWithFront signal) {
      if (signal.id == TorrentClientSignal.ID_PIECE_RECEIVE) {
        this._downloaded += signal.v;
      } else if (signal.id == TorrentClientSignal.ID_PIECE_SEND) {
        this._uploaded += signal.v;
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
    if (_verbose) {
      print("**${message}");
    }
  }
}
