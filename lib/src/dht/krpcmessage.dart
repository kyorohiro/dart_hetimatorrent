library hetimatorrent.dht.krpcmessage;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import 'krpcid.dart';
import '../util/bencode.dart';

class KrpcMessage {}

class KrpcQuery extends KrpcMessage {}

class KrpcResponse extends KrpcMessage {}

class KrpcPingQuery extends KrpcQuery {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);
  //ping Query = {"t":"aa", "y":"q", "q":"ping", "a":{"id":"abcdefghij0123456789"}}
  //bencoded = d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe
  KrpcPingQuery(String transactionId, String queryingNodesId) {
    _messageAsMap = {"t": transactionId, "y": "q", "q": "ping", "a": {"id": queryingNodesId}};
  }
}

class KrpcPingResponse extends KrpcResponse {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  // Response = {"t":"aa", "y":"r", "r": {"id":"mnopqrstuvwxyz123456"}}
  // bencoded = d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re
  KrpcPingResponse(String transactionId, String queryingNodesId) {
    _messageAsMap = {"t": transactionId, "y": "r", "r": {"id": queryingNodesId}};
  }
}

class KrpcFindNodeQuery extends KrpcQuery {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);
  //find_node Query = {"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
  //bencoded = d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe
  KrpcFindNodeQuery(String transactionId, String queryingNodesId, String targetNodeId) {
    _messageAsMap = {"t": transactionId, "y": "q", "q": "find_node", "a": {"id": queryingNodesId, "target": targetNodeId}};
  }
}

class KrpcFindNodeResponse extends KrpcResponse {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  // Response = {"t":"aa", "y":"r", "r": {"id":"mnopqrstuvwxyz123456"}}
  // bencoded = d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re
  KrpcFindNodeResponse(String transactionId, String queryingNodesId, List<int> compactNodeInfo) {
    _messageAsMap = {"t": transactionId, "y": "r", "r": {"id": queryingNodesId, "nodes": compactNodeInfo}};
  }
}

class KrpcError extends KrpcMessage {
  static const int GENERIC_ERROR = 201;
  static const int SERVER_ERROR = 202;
  static const int PROTOCOL_ERROR = 203;
  static const int METHOD_ERROR = 204;

  //  {"t":"aa", "y":"e", "e":[201, "A Generic Error Ocurred"]}
  //
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  KrpcError(String transactionId, int errorCode, String errorMessage, [String messageType = "e"]) {
    _messageAsMap = {"t": transactionId, "y": messageType, "e": [errorCode, errorMessage]};
  }
}

class NodeId {
  KrpcId _id = null;
  List<int> get id => _id.id;

  NodeId(List<int> id) {
    this._id = new KrpcId(id);
  }

  static Future<NodeId> createIDAtRandom([List<int> op = null]) {
    return new Future(() {
      List<int> ret = [];

      Random r = new Random(new DateTime.now().millisecondsSinceEpoch);
      for (int i = 0; i < 20; i++) {
        int v = 0xff;
        if (op != null && i < op.length) {
          v = op[i];
        }
        ret.add(r.nextInt(0xff) & v);
      }
      return new NodeId(ret);
    });
  }
}
