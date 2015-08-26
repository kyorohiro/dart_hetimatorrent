library hetimatorrent.dht.krpcmessage.findnode;

import 'dart:core';
import 'dart:convert';
import '../kid.dart';
import 'dart:typed_data';
import '../kpeerinfo.dart';
import '../kgetpeervalue.dart';
import 'krpcmessage.dart';


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
