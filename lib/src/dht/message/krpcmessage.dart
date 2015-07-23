library hetimatorrent.dht.krpcmessage;

import 'dart:core';
import 'dart:async';
import '../../util/bencode.dart';
import '../../util/hetibencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcping.dart';
import 'krpcfindnode.dart';
import 'krpcgetpeers.dart';
import 'krpcannounce.dart';
import 'dart:convert';

abstract class KrpcResponseInfo {
  String getQueryNameFromTransactionId(String transactionId);
}

class KrpcMessage {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);
  KrpcMessage() {}
  KrpcMessage.fromMap(Map map) {
    _messageAsMap = map;
  }

  static Future<KrpcMessage> decode(EasyParser parser, KrpcResponseInfo info) {
    parser.push();
    return HetiBencode.decode(parser).then((Object v) {
      if (!(v is Map)) {
        throw {};
      }
      Map<String, Object> messageAsMap = v;
      if (KrpcQuery.queryCheck(messageAsMap, null)) {
        KrpcMessage ret = null;
        switch (messageAsMap["q"]) {
          case "ping":
            ret = new KrpcPingQuery.fromMap(messageAsMap);
            break;
          case "find_node":
            ret = new KrpcFindNodeQuery.fromMap(messageAsMap);
            break;
          case "get_peers":
            ret = new KrpcGetPeersQuery.fromMap(messageAsMap);
            break;
          case "announce_peer":
            ret = new KrpcAnnouncePeerQuery.fromMap(messageAsMap);
            break;
          default:
            ret = new KrpcQuery.fromMap(messageAsMap);
            break;
        }

        parser.pop();
        return ret;
      } else if (KrpcResponse.queryCheck(messageAsMap)) {
        KrpcMessage ret = null;
        switch (info.getQueryNameFromTransactionId(messageAsMap["t"])) {
          case "ping":
            ret = new KrpcPingResponse.fromMap(messageAsMap);
            break;
          case "find_node":
            ret = new KrpcFindNodeResponse.fromMap(messageAsMap);
            break;
          case "get_peers":
            ret = new KrpcGetPeersResponse.FromMap(messageAsMap);
            break;
          case "announce_peer":
            ret = new KrpcAnnouncePeerResponse.fromMap(messageAsMap);
            break;
          default:
            ret = new KrpcResponse.fromMap(messageAsMap);
            break;
        }
      } else {
        KrpcMessage ret = new KrpcMessage.fromMap(messageAsMap);
        parser.pop();
        return ret;
      }
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
  KrpcQuery() {}

  KrpcQuery.fromMap(Map map) {
    _messageAsMap = map;
  }
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
    } else if (action != null && messageAsMap["q"] != action) {
      throw {};
    }
    return true;
  }
}

class KrpcResponse extends KrpcMessage {
  KrpcResponse() {}
  KrpcResponse.fromMap(Map map) {
    _messageAsMap = map;
  }
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
