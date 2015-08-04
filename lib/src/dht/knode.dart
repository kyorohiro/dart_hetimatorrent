library hetimatorrent.dht.knode;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'krootingtable.dart';

import 'message/krpcping.dart';
import 'message/krpcfindnode.dart';
import 'message/krpcgetpeers.dart';
import 'kid.dart';
import 'dart:convert';
import '../util/shufflelinkedlist.dart';

import 'message/krpcmessage.dart';
import 'message/krpcannounce.dart';
import 'kpeerinfo.dart';
import 'message/kgetpeervalue.dart';
import 'ai/knodeai.dart';

class KNode extends Object with KrpcResponseInfo {
  HetiSocketBuilder _socketBuilder = null;
  HetiUdpSocket _udpSocket = null;
  HetiUdpSocket get rawUdoSocket => _udpSocket;
  KRootingTable _rootingtable = null;
  Map<String, EasyParser> buffers = {};
  KId _nodeId = null;
  KId get nodeId => _nodeId;
  List<KSendInfo> queryInfo = [];
  KNodeAI _ai = null;
  bool _isStart = false;
  bool get isStart => _isStart;

  KRootingTable get rootingtable => _rootingtable;
  KNodeAI get ai => _ai;
  ShuffleLinkedList<KGetPeerValue> _announced = new ShuffleLinkedList(300);
  ShuffleLinkedList<KGetPeerValue> _searcResult = new ShuffleLinkedList(300);
  List<KGetPeerValue> get announcedPeer => _announced.sequential;
  ShuffleLinkedList<KGetPeerValue> get rawSearchResult => _searcResult;
  ShuffleLinkedList<KGetPeerValue> get rawAnnounced => _announced;
  static int id = 0;

  StreamController<KGetPeerValue> _controller = new StreamController.broadcast();
  Stream<KGetPeerValue> get onGetPeerValue => _controller.stream;
  int _nodeDebugId = 0;
  int get nodeDebugId => _nodeDebugId;

  int _intervalSecondForMaintenance = 5;
  int get intervalSecond => _intervalSecondForMaintenance;

  int _intervalSecondForAnnounce = 60;
  int get intervalSecondForAnnounce => _intervalSecondForAnnounce;

  int _lastAnnouncedTIme = 0;
  bool _verbose = false;
  bool get verbose => _verbose;

  KNode(HetiSocketBuilder socketBuilder, {int kBucketSize: 8, List<int> nodeIdAsList: null, KNodeAI ai: null, intervalSecondForMaintenance: 5, intervalSecondForAnnounce: 60, bool verbose: false}) {
    this._verbose = verbose;
    this._intervalSecondForMaintenance = intervalSecondForMaintenance;
    this._intervalSecondForAnnounce = intervalSecondForAnnounce;
    this._nodeId = (nodeIdAsList == null ? KId.createIDAtRandom() : new KId(nodeIdAsList));
    this._socketBuilder = socketBuilder;
    this._rootingtable = new KRootingTable(kBucketSize, _nodeId);
    this._ai = (ai == null ? new KNodeAIBasic(verbose: verbose) : ai);
    this._nodeDebugId = id++;
  }

  Future start({String ip: "0.0.0.0", int port: 28080}) {
    return new Future(() {
      if (_isStart) {
        throw {};
      }
      _udpSocket = this._socketBuilder.createUdpClient();
      return _udpSocket.bind(ip, port, multicast: true).then((int v) {
        _udpSocket.onReceive().listen((HetiReceiveUdpInfo info) {
          if (!buffers.containsKey("${info.remoteAddress}:${info.remotePort}")) {
            buffers["${info.remoteAddress}:${info.remotePort}"] = new EasyParser(new ArrayBuilder());
            _ai.startParseLoop(this, buffers["${info.remoteAddress}:${info.remotePort}"], info, "${info.remoteAddress}:${info.remotePort}");
          }
          EasyParser parser = buffers["${info.remoteAddress}:${info.remotePort}"];
          (parser.buffer as ArrayBuilder).appendIntList(info.data);
        });
        //////
        _isStart = true;
        _ai.start(this);
        _startTick();
        ////

      });
    }).catchError((e) {
      _isStart = false;
      throw e;
    });
  }

  Future stop() {
    return new Future(() {
      return (_udpSocket == null ? null : _udpSocket.close());
    }).whenComplete(() {
      _isStart = false;
      _ai.stop(this);
    });
  }

  startSearchPeer(KId infoHash, int port) {
    return this._ai.startSearchPeer(this, infoHash, port);
  }

  stopSearchPeer(KId infoHash) {
    return this._ai.stopSearchPeer(this, infoHash);
  }

  addSeardchResult(KGetPeerValue info) {
    _searcResult.addLast(info);
    _controller.add(info);
  }

  addKPeerInfo(KPeerInfo info) => _rootingtable.update(info);

  updateP2PNetwork() => this._ai.updateP2PNetwork(this);

  researchSearchPeer([KId infoHash = null]) => this._ai.researchSearchPeer(this, infoHash);

  addNodeFromIPAndPort(String ip, int port) => this._ai.onAddNodeFromIPAndPort(this, ip, port);

  List<int> getOpaqueWriteToken(KId infoHash, KId nodeID) => KId.createToken(infoHash, nodeID, this.nodeId);

  String getQueryNameFromTransactionId(String transactionId) {
    for (KSendInfo si in queryInfo) {
      if (si._id == transactionId) {
        return si._act;
      }
    }
    return "";
  }

  KSendInfo removeQueryNameFromTransactionId(String transactionId) {
    KSendInfo re = null;
    for (KSendInfo si in queryInfo) {
      if (si._id == transactionId) {
        re = si;
        break;
      }
    }
    queryInfo.remove(re);
    return re;
  }

  Future sendPingQuery(String ip, int port) => _sendMessage(ip, port, new KrpcPingQuery(UTF8.encode("p_${id++}"), _nodeId.id));

  Future sendFindNodeQuery(String ip, int port, List<int> targetNodeId) => _sendMessage(ip, port, new KrpcFindNodeQuery(UTF8.encode("p_${id++}"), _nodeId.id, targetNodeId));

  Future sendGetPeersQuery(String ip, int port, List<int> infoHash) => _sendMessage(ip, port, new KrpcGetPeersQuery(UTF8.encode("p_${id++}"), _nodeId.id, infoHash));

  Future sendAnnouncePeerQuery(String ip, int port, int implied_port, List<int> infoHash, int announcedPort, List<int> opaqueToken) =>
      _sendMessage(ip, port, new KrpcAnnouncePeerQuery(UTF8.encode("p_${id++}"), _nodeId.id, implied_port, infoHash, announcedPort, opaqueToken));

  Future sendPingResponse(String ip, int port, List<int> transactionId) => _sendMessage(ip, port, new KrpcPingResponse(transactionId, _nodeId.id));

  Future sendFindNodeResponse(String ip, int port, List<int> transactionId, List<int> compactNodeInfo) =>
      _sendMessage(ip, port, new KrpcFindNodeResponse(transactionId, this._nodeId.id, compactNodeInfo));

  Future sendGetPeersResponseWithClosestNodes(String ip, int port, List<int> transactionId, List<int> opaqueWriteToken, List<int> compactNodeInfo) =>
      _sendMessage(ip, port, new KrpcGetPeersResponse.withClosestNodes(transactionId, this._nodeId.id, opaqueWriteToken, compactNodeInfo));

  Future sendGetPeersResponseWithPeers(String ip, int port, List<int> transactionId, List<int> opaqueWriteToken, List<List<int>> peerInfoStrings) =>
      _sendMessage(ip, port, new KrpcGetPeersResponse.withPeers(transactionId, this._nodeId.id, opaqueWriteToken, peerInfoStrings));

  Future sendAnnouncePeerResponse(String ip, int port, List<int> transactionId) => _sendMessage(ip, port, new KrpcAnnouncePeerResponse(transactionId, this._nodeId.id));

  Future sendErrorResponse(String ip, int port, int errorCode, List<int> transactionId, [String errorDescription = null]) => _sendMessage(ip, port, new KrpcError(transactionId, errorCode));

  Future _sendMessage(String ip, int port, KrpcMessage message) {
    Completer c = new Completer();
    new Future(() {
      if (message is KrpcQuery) {
        queryInfo.add(new KSendInfo(message.transactionIdAsString, message.q, c));
      }
      if (_verbose == true) {
        String sign = "null";

        if (message is KrpcError) {
          sign = "error";
        } else if (message is KrpcQuery) {
          sign = "query";
        } else if (message is KrpcResponse) {
          sign = "response";
        }
        print("--->send ${sign}[${_nodeDebugId}] ${ip}:${port} ${message}");
        print("--->send ${sign}[${_nodeDebugId}] ${UTF8.decode(message.messageAsBencode,allowMalformed:true)}");
      }
      return _udpSocket.send(message.messageAsBencode, ip, port);
    }).catchError(c.completeError);
    return c.future;
  }

  _startTick() {
    new Future.delayed(new Duration(seconds: this._intervalSecondForMaintenance)).then((_) {
      if (_isStart == false) {
        return;
      }
      try {
        this._ai.onTicket(this);
      } catch (e) {}
      if (_lastAnnouncedTIme == 0) {
        _lastAnnouncedTIme = new DateTime.now().millisecondsSinceEpoch;
      } else {
        int currentTime = new DateTime.now().millisecondsSinceEpoch;
        if (_lastAnnouncedTIme != 0 && (currentTime - _lastAnnouncedTIme) > _intervalSecondForAnnounce * 1000) {
          _lastAnnouncedTIme = currentTime;
          researchSearchPeer(null);
        }
      }
      _startTick();
    }).catchError((e) {});
  }

}

class KSendInfo {
  String _id = "";
  String get id => _id;
  String _act = "";
  String get act => _act;

  int _time = 0;
  int get time => _time;

  Completer _c = null;
  Completer get  c => _c;
  KSendInfo(String id, String act, Completer c) {
    this._id = id;
    this._c = c;
    this._act = act;
    this._time = new DateTime.now().millisecondsSinceEpoch;
  }
}
