library hetimatorrent.dht.knode;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'krootingtable.dart';

import 'kid.dart';
import 'dart:convert';
import '../util/shufflelinkedlist.dart';
import '../util/bencode.dart';
import 'message/krpcmessage.dart';
import 'kpeerinfo.dart';
import 'message/kgetpeervalue.dart';
import 'ai/knodeai.dart';
import 'ai/knodeaibasic.dart';

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
  int get intervalSecondForMaintenance => _intervalSecondForMaintenance;

  int _intervalSecondForAnnounce = 60;
  int get intervalSecondForAnnounce => _intervalSecondForAnnounce;

  bool _verbose = false;
  bool get verbose => _verbose;

  KNode(HetiSocketBuilder socketBuilder,
      {int kBucketSize: 8, List<int> nodeIdAsList: null, KNodeAI ai: null, intervalSecondForMaintenance: 10, intervalSecondForAnnounce: 3 * 60, bool verbose: false}) {
    this._verbose = verbose;
    this._intervalSecondForMaintenance = intervalSecondForMaintenance;
    this._intervalSecondForAnnounce = intervalSecondForAnnounce;
    this._nodeId = (nodeIdAsList == null ? KId.createIDAtRandom() : new KId(nodeIdAsList));
    this._socketBuilder = socketBuilder;
    this._rootingtable = new KRootingTable(kBucketSize, _nodeId);
    this._ai = (ai == null ? new KNodeAIBasic(verbose: verbose) : ai);
    this._nodeDebugId = id++;
  }

  int port = 0;
  Future start({String ip: "0.0.0.0", int port: 28080}) async {
    (_isStart != false ? throw "already started" : 0);
    _udpSocket = this._socketBuilder.createUdpClient();
    this.port = port;
    return _udpSocket.bind(ip, port, multicast: true).then((int v) {
      _udpSocket.onReceive().listen((HetiReceiveUdpInfo info) {
        KrpcMessage.decode(info.data, this).then((KrpcMessage message) {
          onReceiveMessage(info, message);
        });
      });
      //////
      _isStart = true;
      _ai.start(this);
      ai.startTick(this);
    });
  }

  onReceiveMessage(HetiReceiveUdpInfo info, KrpcMessage message) {
    if (verbose == true) {
     // print("--->receive[${nodeDebugId}] ${info.remoteAddress}:${info.remotePort} ${message}");
    }
    if (message.isResonse) {
      KSendInfo rm = removeQueryNameFromTransactionId(UTF8.decode(message.rawMessageMap["t"]));
      this._ai.onReceiveResponse(this, info, message);
      if (rm != null) {
        rm.c.complete(message);
      } else {
        print("----> receive null : [${nodeDebugId}] ${info.remoteAddress} ${info.remotePort}");
      }
    } else if (message.isQuery) {
      this._ai.onReceiveQuery(this, info, message);
    } else if (message.isError) {
      this._ai.onReceiveError(this, info, message);
    } else {
      this._ai.onReceiveUnknown(this, info, message);
    }
    for (KSendInfo i in clearTimeout(20000)) {
      if (i.c.isCompleted == false) {
        i.c.completeError({message: "timeout"});
      }
    }
  }

  Future stop() async {
    if (_isStart == false || _udpSocket == null) {
      return null;
    }
    return _udpSocket.close().whenComplete(() {
      _isStart = false;
      _ai.stop(this);
    });
  }

  Future startSearchValue(KId infoHash, int port, {getPeerOnly: false}) {
    return new Future(() {
      return this._ai.startSearchValue(this, infoHash, port, getPeerOnly: getPeerOnly);
    });
  }

  Future stopSearchPeer(KId infoHash) {
    return new Future(() {
      return this._ai.stopSearchValue(this, infoHash);
    });
  }

  bool containSeardchResult(KGetPeerValue info) {
    return _searcResult.sequential.contains(info);
  }

  addSeardchResult(KGetPeerValue info) {
    bool c = containSeardchResult(info);
    _searcResult.addLast(info);
    if (c == false) {
      _controller.add(info);
    }
  }

  addKPeerInfo(KPeerInfo info) => _rootingtable.update(info);

  updateP2PNetwork() => this._ai.updateP2PNetwork(this);

  researchSearchPeer([KId infoHash = null]) => this._ai.researchSearchPeer(this, infoHash);

  addBootNode(String ip, int port) => this._ai.onAddNodeFromIPAndPort(this, ip, port);

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

  List<KSendInfo> clearTimeout(int timeout) {
    int currentTime = new DateTime.now().millisecondsSinceEpoch;
    List<KSendInfo> ret = [];
    for (KSendInfo si in queryInfo) {
      if (currentTime - si._time > timeout) {
        ret.add(si);
      }
    }
    for (KSendInfo i in ret) {
      queryInfo.remove(i);
    }
    return ret;
  }

  Future sendPingQuery(String ip, int port) => _sendMessage(ip, port, KrpcPing.createQuery(_nodeId.value));

  Future sendFindNodeQuery(String ip, int port, List<int> targetNodeId) => _sendMessage(ip, port, KrpcFindNode.createQuery(targetNodeId, _nodeId.value));

  Future sendGetPeersQuery(String ip, int port, List<int> infoHash) => _sendMessage(ip, port, KrpcGetPeers.createQuery(_nodeId.value, infoHash));
  
  Future sendAnnouncePeerQuery(String ip, int port, int implied_port, List<int> infoHash, int announcedPort, List<int> opaqueToken) =>_sendMessage(ip, port, KrpcAnnounce.createQuery(_nodeId.value, implied_port, infoHash, announcedPort, opaqueToken));


  Future sendPingResponse(String ip, int port, List<int> transactionId) => _sendMessage(ip, port, KrpcPing.createResponse(_nodeId.value, transactionId));

  Future sendFindNodeResponse(String ip, int port, List<int> transactionId, List<int> compactNodeInfo) =>
      _sendMessage(ip, port, KrpcFindNode.createResponse(compactNodeInfo, this._nodeId.value, transactionId));

  Future sendGetPeersResponseWithClosestNodes(String ip, int port, List<int> transactionId, List<int> opaqueWriteToken, List<int> compactNodeInfo)  =>
      _sendMessage(ip, port, KrpcGetPeers.createResponseWithClosestNodes(transactionId, this._nodeId.value, opaqueWriteToken, compactNodeInfo));    

  Future sendGetPeersResponseWithPeers(String ip, int port, List<int> transactionId, List<int> opaqueWriteToken, List<List<int>> peerInfoStrings) =>
    _sendMessage(ip, port, KrpcGetPeers.createResponseWithPeers(transactionId, this._nodeId.value, opaqueWriteToken, peerInfoStrings));

  Future sendAnnouncePeerResponse(String ip, int port, List<int> transactionId) =>
   _sendMessage(ip, port, KrpcAnnounce.createResponse(transactionId, this._nodeId.value));

  Future sendErrorResponse(String ip, int port, int errorCode, List<int> transactionId, [String errorDescription = null]) => _sendMessage(ip, port, KrpcError.createMessage(transactionId, errorCode));

  Future _sendMessage(String ip, int port, KrpcMessage message) {
    Completer c = new Completer();
    new Future(() {
      if (message.isQuery) {
        queryInfo.add(new KSendInfo(message.transactionIdAsString, message.queryAsString, c));
      }
      if (_verbose == true) {
        String sign = "null";

        if (message is KrpcError) {
          sign = "error";
        } else if (message.isQuery) {
          sign = "query";
        } else if (message.isResonse) {
          sign = "response";
        }
       // print("--->send ${sign}[${_nodeDebugId}] ${ip}:${port} ${message}");
      }
      return _udpSocket.send(message.messageAsBencode, ip, port);
    }).catchError(c.completeError);
    return c.future;
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
  Completer get c => _c;
  KSendInfo(String id, String act, Completer c) {
    this._id = id;
    this._c = c;
    this._act = act;
    this._time = new DateTime.now().millisecondsSinceEpoch;
  }
}
