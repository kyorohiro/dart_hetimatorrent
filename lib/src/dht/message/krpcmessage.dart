library hetimatorrent.dht.krpcmessage;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import '../../util/bencode.dart';
import '../../util/hetibencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcping.dart';
import 'krpcfindnode.dart';
import 'krpcgetpeers.dart';
import 'krpcannounce.dart';
import 'dart:convert';
import '../kid.dart';
import 'dart:typed_data';
import '../knode.dart';

abstract class KrpcResponseInfo {
  String getQueryNameFromTransactionId(String transactionId);
}

class KrpcMessage {
  static const int NONE_MESSAGE = 0;
  static const int NONE_QUERY = 100;
  static const int NONE_RESPONSE = 110;
  static const int PING_QUERY = 101;
  static const int PING_RESPONSE = 111;
  static const int FIND_NODE_QUERY = 102;
  static const int FIND_NODE_RESPONSE = 112;
  static const int GET_PEERS_QUERY = 103;
  static const int GET_PEERS_RESPONSE = 113;
  static const int ANNOUNCE_QUERY = 104;
  static const int ANNOUNCE_RESPONSE = 114;
  static const int ERROR = 200;

  Map<String, Object> _messageAsMap = {};
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  int _id = NONE_MESSAGE;
  int get messageSignature => _id;

  List<int> get transactionId => (_messageAsMap["t"] is String ? UTF8.encode(_messageAsMap["t"]) : _messageAsMap["t"]);
  String get transactionIdAsString => UTF8.decode(transactionId);
  List<int> get messageType => (_messageAsMap["y"] is String ? UTF8.encode(_messageAsMap["y"]) : _messageAsMap["y"]);
  String get messageTypeAsString => UTF8.decode(messageType);

  int get errorCode  {
    List<Object> errorCountainer = _messageAsMap["e"];
    return (errorCountainer !=null && errorCountainer.length ==2 ?errorCountainer[0]:null);
  }
  List<int> get errorMessage {
    List<Object> errorCountainer = _messageAsMap["e"];
    Object errorMessage = (errorCountainer !=null && errorCountainer.length ==2 ?errorCountainer[1]:null);
    return (errorMessage is String ? UTF8.encode(errorMessage) : errorMessage);
  }
  String get errorMessageAsString => UTF8.decode(errorMessage,allowMalformed: true);

  
  KrpcMessage(int id) {
    this._id = id;
  }

  KrpcMessage.fromMap(Map map) {
    _messageAsMap = map;
  }

  Map<String, Object> get rawMessageMap => _messageAsMap;

  static Future<KrpcMessage> decode(List<int> data, KrpcResponseInfo info) async {
    Map<String, Object> messageAsMap = null;
    try {
      Object v = Bencode.decode(data);
      messageAsMap = v;
    } catch (e) {
      throw {};
    }

    if (KrpcQuery.queryCheck(messageAsMap, null)) {
      KrpcMessage ret = null;
      String q = "";
      if (messageAsMap["q"] is String) {
        q = messageAsMap["q"];
      } else {
        q = UTF8.decode(messageAsMap["q"]);
      }
      switch (q) {
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
      return ret;
    } else if (KrpcResponse.queryCheck(messageAsMap)) {
      KrpcMessage ret = null;
      switch (info.getQueryNameFromTransactionId(UTF8.decode(messageAsMap["t"]))) {
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
      return ret;
    } else if (KrpcError.queryCheck(messageAsMap)) {
      KrpcMessage ret = new KrpcMessage.fromMap(messageAsMap);
      return ret;
    }
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
  KrpcQuery(int id) : super(id) {}

  String get q {
    if (rawMessageMap["q"] is String) {
      return rawMessageMap["q"];
    } else {
      return UTF8.decode(rawMessageMap["q"]);
    }
  }

  KId get queryingNodesId {
    Map<String, Object> a = messageAsMap["a"];
    return new KId(a["id"] as List<int>);
  }

  KrpcQuery.fromMap(Map map) : super(KrpcMessage.NONE_QUERY) {
    _messageAsMap = map;
  }

  String toString() {
    return "null_message@query:${this.rawMessageMap}";
  }

  static bool queryCheck(Map<String, Object> messageAsMap, String action) {
    if (!messageAsMap.containsKey("a")) {
      return false;
    }
    if (!(messageAsMap["a"] is Map)) {
      return false;
    }
    Map<String, Object> a = messageAsMap["a"];
    if (!(a is Map) || !a.containsKey("id") || !messageAsMap.containsKey("t") || !messageAsMap.containsKey("y")) {
      return false;
    }
    if (messageAsMap["q"] is List) {
      if (action != null && UTF8.decode(messageAsMap["q"]) != action) {
        throw {};
      }
    } else if (action != null && messageAsMap["q"] != action) {
      throw {};
    }
    return true;
  }
}

class KrpcResponse extends KrpcMessage {
  KId get queriedNodesId {
    Map<String, Object> r = messageAsMap["r"];
    return new KId(r["id"] as List<int>);
  }

  KrpcResponse(int id) : super(id) {}
  KrpcResponse.fromMap(Map map) : super(KrpcMessage.NONE_RESPONSE) {
    _messageAsMap = map;
  }
  static bool queryCheck(Map<String, Object> messageAsMap) {
    if (!messageAsMap.containsKey("r")) {
      return false;
    }
    if (!(messageAsMap["r"] is Map)) {
      return false;
    }
    Map<String, Object> r = messageAsMap["r"];
    if (!(r is Map) || !r.containsKey("id") || !messageAsMap.containsKey("t") || !messageAsMap.containsKey("y")) {
      return false;
    }
    return true;
  }
}

class KrpcError {
  static const int GENERIC_ERROR = 201;
  static const int SERVER_ERROR = 202;
  static const int PROTOCOL_ERROR = 203;
  static const int METHOD_ERROR = 204;

  static createMessage(List<int> transactionId, int errorCode) {
    return new KrpcMessage.fromMap({"t": transactionId, "y": "e", "e": [errorCode, KrpcError.errorDescription(errorCode)]});
  }

  static String errorDescription(int errorCode) {
    switch (errorCode) {
      case 201:
        return "Generic Error";
      case 202:
        return "Server Error";
      case 203:
        return "Protocol Error, such as a malformed packet, invalid arguments, or bad token";
      case 204:
        return "Method Unknown";
      default:
        return "Unknown";
    }
  }

  static bool queryCheck(Map<String, Object> messageAsMap) {
    if (!messageAsMap.containsKey("e")) {
      return false;
    }
    Object e = messageAsMap["e"];
    if (!(e is List) || (e as List).length < 2 || !messageAsMap.containsKey("t") || !messageAsMap.containsKey("y")) {
      return false;
    }
    return true;
  }



}
