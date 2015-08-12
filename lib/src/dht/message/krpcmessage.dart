library hetimatorrent.dht.krpcmessage;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import '../../util/bencode.dart';
import '../kid.dart';
import 'dart:typed_data';
import '../kpeerinfo.dart';
import 'kgetpeervalue.dart';

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

  List<int> get transactionId => (_messageAsMap["t"] is String ? UTF8.encode(_messageAsMap["t"]) : _messageAsMap["t"]);
  String get transactionIdAsString => UTF8.decode(transactionId);
  List<int> get messageType => (_messageAsMap["y"] is String ? UTF8.encode(_messageAsMap["y"]) : _messageAsMap["y"]);
  String get messageTypeAsString => UTF8.decode(messageType);

  List<int> get query => (_messageAsMap["q"] is String ? UTF8.encode(_messageAsMap["q"]) : _messageAsMap["q"]);
  String get queryAsString => UTF8.decode(query);

  int get errorCode {
    List<Object> errorCountainer = _messageAsMap["e"];
    return (errorCountainer != null && errorCountainer.length == 2 ? errorCountainer[0] : null);
  }

  List<int> get errorMessage {
    List<Object> errorCountainer = _messageAsMap["e"];
    Object errorMessage = (errorCountainer != null && errorCountainer.length == 2 ? errorCountainer[1] : []);
    return (errorMessage is String ? UTF8.encode(errorMessage) : errorMessage);
  }

  String get errorMessageAsString => UTF8.decode(errorMessage, allowMalformed: true);

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

  List<int> get target {
    Map<String, Object> queryCountainer = _messageAsMap["a"];
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

  List<int> get infoHash {
    Map<String, Object> a = messageAsMap["a"];
    return a["info_hash"];
  }

  KId get infoHashAsKId => new KId(infoHash);

  //
  //

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

  int get impliedPort {
    Map<String, Object> a = messageAsMap["a"];
    return a["implied_port"];
  }

  int get port {
    Map<String, Object> a = messageAsMap["a"];
    return a["port"];
  }

  KrpcMessage() {}

  KrpcMessage.fromMap(Map map) {
    _messageAsMap = map;
  }

  Map<String, Object> get rawMessageMap => _messageAsMap;

  static Future<KrpcMessage> decode(List<int> data) async {
    Map<String, Object> messageAsMap = null;
    try {
      Object v = Bencode.decode(data);
      messageAsMap = v;
    } catch (e) {
      throw {};
    }
    return new KrpcMessage.fromMap(messageAsMap);
  }

  String toString() {
    switch (messageTypeAsString) {
      case "e":
        return "ERROR";
      case "q":
        switch (queryAsString) {
          case "ping":
            return "q->PING_QUERY";
          case "find_node":
            return "q->FIND_NODE_QUERY";
          case "get_peers":
            return "q->GET_PEERS_QUERY";
          case "announce_peer":
            return "q->ANNOUNCE_QUERY";
        }
        return "q->NONE_QUERY";
      case "r":
        if (transactionIdAsString.contains("pi")) {
          return "r->PING_RESPONSE";
        } else if (transactionIdAsString.contains("fi")) {
          return "r->FIND_NODE_RESPONSE";
        } else if (transactionIdAsString.contains("ge")) {
          return "r->GET_PEERS_RESPONSE";
        } else if (transactionIdAsString.contains("an")) {
          return "r->ANNOUNCE_RESPONSE";
        }
        return "r->NONE_RESPONSE";
    }
    return "?->NONE_MESSAGE";
  }
}
