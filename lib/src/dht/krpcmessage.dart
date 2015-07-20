library hetimatorrent.dht.krpcmessage;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import 'krpcid.dart';
import '../util/bencode.dart';
import '../util/hetibencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcping.dart';
import 'dart:convert';

class KrpcMessage {
  static Future<KrpcMessage> decode(EasyParser parser) {
    parser.push();
    return HetiBencode.decode(parser).then((Object v) {
      if (!(v is Map)) {
        throw {};
      }
      KrpcMessage ret = null;
      Map<String, Object> messageAsMap = v;
      if (!messageAsMap.containsKey("t") || !messageAsMap.containsKey("y")) {
        throw {};
      }
      if (messageAsMap["y"] == "q") {
        switch (messageAsMap["q"]) {
          case "ping":
            ret = new KrpcPingQuery.fromMap(v);
            break;
        }
      } else if (messageAsMap["y"] == "r") {} else {}

      parser.pop();
      return ret;
    }).catchError((e) {
      parser.back();
      parser.pop();
      throw e;
    });
  }
  
  static Future<KrpcMessage> decodeTest(EasyParser parser, Function a) {
    parser.push();
    return HetiBencode.decode(parser).then((Object v) {
      if (!(v is Map)) {
        throw {};
      }
      KrpcMessage ret = a(v);
      parser.pop();
      return ret;
    }).catchError((e) {
      parser.back();
      parser.pop();
      throw e;
    });
  }
}

class KrpcQuery extends KrpcMessage {
  static bool queryCheck(Map<String, Object> messageAsMap, String action) {
    if (!messageAsMap.containsKey("a")) {
      return false;
    }
    Map<String, Object> a = messageAsMap["a"];
    if (!(a is Map) || !a.containsKey("id") || !messageAsMap.containsKey("t") || !messageAsMap.containsKey("y")) {
      return false;
    }
    if (messageAsMap["q"] is List) {
      if (UTF8.decode(messageAsMap["q"]) != action) {
        throw {};
      }
    } else if (messageAsMap["q"] != action) {
      throw {};
    }
    return true;
  }
}

class KrpcResponse extends KrpcMessage {
  static bool queryCheck(Map<String, Object> messageAsMap) {
    if (!messageAsMap.containsKey("r")) {
      return false;
    }
    Map<String, Object> r = messageAsMap["r"];
    if (!(r is Map) || !r.containsKey("id") || !messageAsMap.containsKey("t") || !messageAsMap.containsKey("y")) {
      return false;
    }
    return true;
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
