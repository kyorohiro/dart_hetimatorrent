library hetimatorrent.dht.krpgetpeers;

import 'dart:core';
import 'dart:async';
import '../util/bencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcmessage.dart';

class KrpcGetPeersQuery extends KrpcQuery {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);
  //find_node Query = {"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
  //bencoded = d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe
  KrpcGetPeersQuery(String transactionId, String queryingNodesId, List<int> infoHash) {
    _messageAsMap = {
      "a": {"id": queryingNodesId, "info_hash": infoHash},
      "q": "get_peers",
      "t": transactionId, 
      "y": "q"};
  }
  
  KrpcGetPeersQuery.fromMap(Map<String, Object> messageAsMap) {
    if (!KrpcQuery.queryCheck(messageAsMap, "get_peers")) {
      throw {};
    }
    Map<String, Object> a = messageAsMap["a"];
    _messageAsMap = {
      "a": {"id": a["id"], "info_hash": a["info_hash"]},
      "q": "get_peers",
      "t": messageAsMap["t"], 
      "y": "q"
      };
  }

  static Future<KrpcGetPeersQuery> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      return new KrpcGetPeersQuery.fromMap(v);
    });
  }
}

class KrpcGetPeersResponse extends KrpcResponse {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  // Response = {"t":"aa", "y":"r", "r": {"id":"mnopqrstuvwxyz123456"}}
  // bencoded = d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re
  KrpcGetPeersResponse.withPeers(String transactionId, String queryingNodesId, String opaqueWriteToken, List<String> peerInfoStrings) {
    _messageAsMap = {"t": transactionId, "y": "r", "r": {"id": queryingNodesId, "token": opaqueWriteToken, "values": peerInfoStrings}};
  }
  //Response with closest nodes = {"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "nodes": "def456..."}}
  // bencoded = d1:rd2:id20:abcdefghij01234567895:nodes9:def456...5:token8:aoeusnthe1:t2:aa1:y1:re
  KrpcGetPeersResponse.withClosestNodes(String transactionId, String queryingNodesId, String opaqueWriteToken, List<int> compactNodeInfo) {
    _messageAsMap = {"t": transactionId, "y": "r", "r": {"id": queryingNodesId, "token": opaqueWriteToken, "nodes": compactNodeInfo}};
  }
}


