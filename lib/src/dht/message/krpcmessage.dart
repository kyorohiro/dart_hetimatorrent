library hetimatorrent.dht.krpcmessage;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import '../../util/bencode.dart';
import '../kid.dart';
import 'dart:typed_data';
import '../message/krpcmessage_builder.dart';

class KrpcMessage {
  //
  static const int GENERIC_ERROR = 201;
  static const int SERVER_ERROR = 202;
  static const int PROTOCOL_ERROR = 203;
  static const int METHOD_ERROR = 204;
  //
  static const String QUERY_PING = "ping";
  static const String QUERY_FIND_NODE = "find_node";
  static const String QUERY_GET_PEERS = "get_peers";
  static const String QUERY_ANNOUNCE = "announce_peer";

  Map<String, Object> _messageAsMap = {};
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  Map<String, Object> get rawMessageAsMap => _messageAsMap;
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  bool get isResonse => messageTypeAsString == "r";
  bool get isQuery => messageTypeAsString == "q";
  bool get isError => messageTypeAsString == "e";

  String get queryFromTransactionId {
    if (transactionIdAsString.contains("pi")) {
      return QUERY_PING;
    } else if (transactionIdAsString.contains("fi")) {
      return QUERY_FIND_NODE;
    } else if (transactionIdAsString.contains("ge")) {
      return QUERY_GET_PEERS;
    } else if (transactionIdAsString.contains("an")) {
      return QUERY_ANNOUNCE;
    }
    return "";
  }

  //
  List<int> get transactionId => (_messageAsMap["t"] is String ? UTF8.encode(_messageAsMap["t"]) : _messageAsMap["t"]);
  String get transactionIdAsString => UTF8.decode(transactionId);

  //
  List<int> get messageType => (_messageAsMap["y"] is String ? UTF8.encode(_messageAsMap["y"]) : _messageAsMap["y"]);
  String get messageTypeAsString => UTF8.decode(messageType);

  //
  List<int> get query => (_messageAsMap["q"] is String ? UTF8.encode(_messageAsMap["q"]) : _messageAsMap["q"]);
  String get queryAsString => UTF8.decode(query);

  //
  int get errorCode {
    List<Object> errorCountainer = _messageAsMap["e"];
    return (errorCountainer != null && errorCountainer.length == 2 ? errorCountainer[0] : null);
  }

  //
  List<int> get errorMessage {
    List<Object> errorCountainer = _messageAsMap["e"];
    Object errorMessage = (errorCountainer != null && errorCountainer.length == 2 ? errorCountainer[1] : []);
    return (errorMessage is String ? UTF8.encode(errorMessage) : errorMessage);
  }
  String get errorMessageAsString => UTF8.decode(errorMessage, allowMalformed: true);

  //
  List<int> get _queryingNodeId {
    Map<String, Object> queryCountainer = _messageAsMap["a"];
    return (queryCountainer["id"] is String ? UTF8.encode(queryCountainer["id"]) : queryCountainer["id"]);
  }

  List<int> get _queriedNodesId {
    Map<String, Object> responseCountainer = _messageAsMap["r"];
    return (responseCountainer["id"] is String ? UTF8.encode(responseCountainer["id"]) : responseCountainer["id"]);
  }

  List<int> get nodeId {
    switch (messageTypeAsString) {
      case "q":
        return _queryingNodeId;
      case "r":
        return _queriedNodesId;
    }
    return [];
  }

  String get nodeIdAsString => UTF8.decode(nodeId, allowMalformed: true);
  KId get nodeIdAsKId => new KId(nodeId);

  KrpcMessage() {}

  KrpcMessage.fromMap(Map map) {
    _messageAsMap = map;
  }

  Map<String, Object> get rawMessageMap => _messageAsMap;

  static Future<KrpcMessage> decode(List<int> data, {errorWithThrow:true}) async {
    Map<String, Object> messageAsMap = null;
    try {
      Object v = Bencode.decode(data);
      messageAsMap = v;
    } catch (e) {
      throw {};
    }
    return new KrpcMessage.fromMap(messageAsMap);
  }

  KrpcPing toPing() {
    return new KrpcPing(this);
  }

  KrpcFindNode toFindNode() {
    return new KrpcFindNode(this);
  }

  KrpcAnnounce toAnnounce() {
    return new KrpcAnnounce(this);
  }

  KrpcGetPeers toKrpcGetPeers() {
    return new KrpcGetPeers(this);
  }

  String toString() {
    String sign = "null";
    if (isError) {
      sign = "error";
    } else if (isQuery) {
      sign = "query";
    } else if (isResonse) {
      sign = "response";
    }
    return sign;
  }
}

class KrpcQuery {
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

class KrpcResponse {
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
  static KrpcMessage createResponse(List<int> transactionId, int errorCode) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
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
