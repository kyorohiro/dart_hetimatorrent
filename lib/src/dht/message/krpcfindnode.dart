library hetimatorrent.dht.krpcfindnode;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../kid.dart';
import '../../util/bencode.dart';
import '../../util/hetibencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcmessage.dart';

class KrpcFindNodeQuery extends KrpcQuery {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);
  //find_node Query = {"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
  //bencoded = d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe
  KrpcFindNodeQuery(String transactionId, String queryingNodesId, String targetNodeId) {
    _messageAsMap = {"a": {"id": queryingNodesId, "target": targetNodeId}, "q": "find_node", "t": transactionId, "y": "q"};
  }

  KrpcFindNodeQuery.fromMap(Map<String, Object> messageAsMap) {
    if (!KrpcQuery.queryCheck(messageAsMap, "find_node")) {
      throw {};
    }
    Map<String, Object> a = messageAsMap["a"];
    _messageAsMap = {"a": {"id": a["id"], "target": a["target"]}, "q": "find_node", "t": messageAsMap["t"], "y": "q"};
  }

  static Future<KrpcFindNodeQuery> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      return new KrpcFindNodeQuery.fromMap(v);
    });
  }
}

class KrpcFindNodeResponse extends KrpcResponse {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  // Response with peers = {"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "values": ["axje.u", "idhtnm"]}}
  // bencoded = d1:rd2:id20:abcdefghij01234567895:token8:aoeusnth6:valuesl6:axje.u6:idhtnmee1:t2:aa1:y1:re
  KrpcFindNodeResponse(String transactionId, String queryingNodesId, List<int> compactNodeInfo) {
    _messageAsMap = {"r": {"id": queryingNodesId, "nodes": compactNodeInfo},"t": transactionId, "y": "r"};
  }
  KrpcFindNodeResponse.fromMap(Map<String, Object> messageAsMap) {
    if (!KrpcResponse.queryCheck(messageAsMap)) {
      throw {};
    }
    Map<String, Object> r = messageAsMap["r"];
    _messageAsMap = {"r": {"id": r["id"], "nodes": r["nodes"]}, "t": messageAsMap["t"], "y": "r"};
  }

  static Future<KrpcFindNodeResponse> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      return new KrpcFindNodeResponse.fromMap(v);
    });
  }
}
