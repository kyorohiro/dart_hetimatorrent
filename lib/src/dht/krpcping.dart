library hetimatorrent.dht.krpcping;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import 'krpcid.dart';
import '../util/bencode.dart';
import '../util/hetibencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcmessage.dart';

class KrpcPingQuery extends KrpcQuery {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);
  //ping Query = {"t":"aa", "y":"q", "q":"ping", "a":{"id":"abcdefghij0123456789"}}
  //bencoded = d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe
  KrpcPingQuery(String transactionId, String queryingNodesId) {
    _messageAsMap = {"a": {"id": queryingNodesId}, "q": "ping", "t": transactionId, "y": "q"};
  }
}

class KrpcPingResponse extends KrpcResponse {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  // Response = {"t":"aa", "y":"r", "r": {"id":"mnopqrstuvwxyz123456"}}
  // bencoded = d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re
  KrpcPingResponse(String transactionId, String queryingNodesId) {
    _messageAsMap = {"r": {"id": queryingNodesId}, "t": transactionId, "y": "r"};
  }

  KrpcPingResponse.fromMap(Map<String, Object> messageAsMap) {
    if (!messageAsMap.containsKey("r")) {
      throw {};
    }
    Map<String, Object> r = messageAsMap["r"];
    if (!(r is Map) || !r.containsKey("id") || !messageAsMap.containsKey("t") || !messageAsMap.containsKey("y")) {
      throw {};
    }
    _messageAsMap = {"r": {"id": r["id"]}, "t": messageAsMap["t"], "y": messageAsMap["y"]};
  }

  static Future<KrpcPingResponse> decode(EasyParser parser) {
    parser.push();
    return HetiBencode.decode(parser).then((Object v) {
      if (!(v is Map)) {
        throw {};
      }
      KrpcPingResponse ret = new KrpcPingResponse.fromMap(v);
      parser.pop();
      return ret;
    }).catchError((e) {
      parser.back();
      parser.pop();
      throw e;
    });
  }
}

