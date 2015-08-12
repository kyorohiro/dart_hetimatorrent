library hetimatorrent.dht.krpcmessage.builder;

import 'dart:core';
import 'dart:convert';
import '../kid.dart';
import 'dart:typed_data';
import '../kpeerinfo.dart';
import 'kgetpeervalue.dart';
import 'krpcmessage.dart';


class KrpcPing  extends KrpcMessage{

  KrpcPing(KrpcMessage message) : super.fromMap(message.rawMessageAsMap) {
    
  }

  static int queryID = 0;
  static KrpcMessage createQuery(List<int> queryingNodesId) {
    List<int> transactionId = UTF8.encode("pi${queryID++}");
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    return new KrpcMessage.fromMap({"a": {"id": queryingNodesId}, "q": "ping", "t": transactionId, "y": "q"});
  }
  static KrpcMessage createResponse(List<int> queryingNodesId, List<int> transactionId) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId}, "t": transactionId, "y": "r"});
  }
}

class KrpcFindNode extends KrpcMessage{

  static int queryID = 0;

  KrpcFindNode(KrpcMessage message) : super.fromMap(message.rawMessageAsMap) {
    
  }

  List<int> get target {
    Map<String, Object> queryCountainer = rawMessageAsMap["a"];
    return (queryCountainer["target"] is String ? UTF8.encode(queryCountainer["target"]) : queryCountainer["target"]);
  }

  String get targetAsString => UTF8.decode(target, allowMalformed: true);
  KId get targetAsKId => new KId(target);

  List<int> get compactNodeInfo {
    Map<String, Object> r = rawMessageMap["r"];
    return r["nodes"];
  }

  List<KPeerInfo> get compactNodeInfoAsKPeerInfo {
    List<KPeerInfo> ret = [];
    List<int> infos = compactNodeInfo;

    for (int i = 0; i < infos.length ~/ 26; i++) {
      ret.add(new KPeerInfo.fromBytes(infos, i * 26, 26));
    }
    return ret;
  }

  static KrpcMessage createQuery(List<int> queryingNodesId, List<int> targetNodeId) {
    List<int> transactionId = UTF8.encode("fi${queryID++}");
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    targetNodeId = (targetNodeId is Uint8List ? targetNodeId : new Uint8List.fromList(targetNodeId));
    return new KrpcMessage.fromMap({"a": {"id": queryingNodesId, "target": targetNodeId}, "q": "find_node", "t": transactionId, "y": "q"});
  }

  static KrpcMessage createResponse(List<int> compactNodeInfo, List<int> queryingNodesId, List<int> transactionId) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    compactNodeInfo = (compactNodeInfo is Uint8List ? compactNodeInfo : new Uint8List.fromList(compactNodeInfo));
    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId, "nodes": compactNodeInfo}, "t": transactionId, "y": "r"});
  }
}


class KrpcGetPeers extends KrpcMessage {

  KrpcGetPeers(KrpcMessage message) : super.fromMap(message.rawMessageAsMap) {
    
  }
  
  List<int> get compactNodeInfo {
    Map<String, Object> r = rawMessageMap["r"];
    return r["nodes"];
  }

  List<KPeerInfo> get compactNodeInfoAsKPeerInfo {
    List<KPeerInfo> ret = [];
    List<int> infos = compactNodeInfo;

    for (int i = 0; i < infos.length ~/ 26; i++) {
      ret.add(new KPeerInfo.fromBytes(infos, i * 26, 26));
    }
    return ret;
  }

  List<int> get infoHash {
    Map<String, Object> a = messageAsMap["a"];
    return a["info_hash"];
  }

  KId get infoHashAsKId => new KId(infoHash);
  
  bool get haveValue {
    if (((messageAsMap)["r"] as Map).containsKey("values") == true) {
      return true;
    } else {
      return false;
    }
  }

  List<KGetPeerValue> valuesAsKAnnounceInfo(List<int> infoHash) {
    if (haveValue == false) {
      return [];
    }
    Map<String, Object> r = messageAsMap["r"];
    List<Uint8List> values = r["values"];
    List<KGetPeerValue> ret = [];
    for (Uint8List l in values) {
      KGetPeerValue a = new KGetPeerValue.fromCompactIpPort(l, infoHash);
      ret.add(a);
    }
    return ret;
  }

  List<int> get tokenAsKId {
    Map<String, Object> r = messageAsMap["r"];
    return r["token"];
  }

  List<int> get token {
    Map<String, Object> a = messageAsMap["a"];
    return a["token"];
  }


  static int queryID = 0;
  static KrpcMessage createQuery(List<int> queryingNodesId, List<int> infoHash) {
    List<int> transactionId = UTF8.encode("ge${queryID++}");
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    infoHash = (infoHash is Uint8List ? infoHash : new Uint8List.fromList(infoHash));
    return new KrpcMessage.fromMap({"a": {"id": queryingNodesId, "info_hash": infoHash}, "q": "get_peers", "t": transactionId, "y": "q"});
  }

  static createResponseWithPeers(List<int> transactionId, List<int> queryingNodesId, List<int> opaqueWriteToken, List<List<int>> peerInfoStrings) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    opaqueWriteToken = (opaqueWriteToken is Uint8List ? opaqueWriteToken : new Uint8List.fromList(opaqueWriteToken));

    for (int i = 0; i < peerInfoStrings.length; i++) {
      if (!(peerInfoStrings[i] is Uint8List)) {
        peerInfoStrings[i] = new Uint8List.fromList(peerInfoStrings[i]);
      }
    }
    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId, "token": opaqueWriteToken, "values": peerInfoStrings}, "t": transactionId, "y": "r"});
  }

  static createResponseWithClosestNodes(List<int> transactionId, List<int> queryingNodesId, List<int> opaqueWriteToken, List<int> compactNodeInfo) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    opaqueWriteToken = (opaqueWriteToken is Uint8List ? opaqueWriteToken : new Uint8List.fromList(opaqueWriteToken));
    compactNodeInfo = (compactNodeInfo is Uint8List ? compactNodeInfo : new Uint8List.fromList(compactNodeInfo));

    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId, "nodes": compactNodeInfo, "token": opaqueWriteToken}, "t": transactionId, "y": "r"});
  }
}


class KrpcAnnounce extends KrpcMessage{

  KrpcAnnounce(KrpcMessage message) : super.fromMap(message.rawMessageAsMap) {
    
  }
  List<int> get tokenAsKId {
    Map<String, Object> r = messageAsMap["r"];
    return r["token"];
  }

  List<int> get token {
    Map<String, Object> a = messageAsMap["a"];
    return a["token"];
  }

  int get impliedPort {
    Map<String, Object> a = messageAsMap["a"];
    return a["implied_port"];
  }

  int get port {
    Map<String, Object> a = messageAsMap["a"];
    return a["port"];
  }
  
  List<int> get infoHash {
    Map<String, Object> a = messageAsMap["a"];
    return a["info_hash"];
  }

  KId get infoHashAsKId => new KId(infoHash);

  static int queryID = 0;
  static KrpcMessage createQuery(List<int> queryingNodesId, int implied_port, List<int> infoHash, int port, List<int> opaqueToken) {
    List<int> transactionId = UTF8.encode("an${queryID++}");
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    infoHash = (infoHash is Uint8List ? infoHash : new Uint8List.fromList(infoHash));
    opaqueToken = (opaqueToken is Uint8List ? opaqueToken : new Uint8List.fromList(opaqueToken));

    return new KrpcMessage.fromMap(
        {"a": {"id": queryingNodesId, "info_hash": infoHash, "implied_port": implied_port, "port": port, "token": opaqueToken}, "q": "announce_peer", "t": transactionId, "y": "q"});
  }

  static KrpcMessage createResponse(List<int> transactionId, List<int> queryingNodesId) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId}, "t": transactionId, "y": "r"});
  }
}
