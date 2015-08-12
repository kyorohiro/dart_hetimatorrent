library hetimatorrent.dht.krpcmessage.builder;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import '../../util/bencode.dart';
import '../kid.dart';
import 'dart:typed_data';
import '../kpeerinfo.dart';
import 'kgetpeervalue.dart';
import 'krpcmessage.dart';

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

class KrpcPing {
  static int queryID = 0;
  static KrpcMessage createQuery(List<int> queryingNodesId) {
    List<int> transactionId = UTF8.encode("pi${queryID++}");
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    return new KrpcMessage.fromMap({"a": {"id": queryingNodesId}, "q": "ping", "t": transactionId, "y": "q"});
  }
  static KrpcMessage createResponse(List<int> queryingNodesId, List<int> transactionId) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId}, "t": transactionId, "y": "r"});
  }
}

class KrpcFindNode {
  static int queryID = 0;

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

class KrpcGetPeers {
  static int queryID = 0;
  static KrpcMessage createQuery(List<int> queryingNodesId, List<int> infoHash) {
    List<int> transactionId = UTF8.encode("ge${queryID++}");
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    infoHash = (infoHash is Uint8List ? infoHash : new Uint8List.fromList(infoHash));
    return new KrpcMessage.fromMap({"a": {"id": queryingNodesId, "info_hash": infoHash}, "q": "get_peers", "t": transactionId, "y": "q"});
  }

  static createResponseWithPeers(List<int> transactionId, List<int> queryingNodesId, List<int> opaqueWriteToken, List<List<int>> peerInfoStrings) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    opaqueWriteToken = (opaqueWriteToken is Uint8List ? opaqueWriteToken : new Uint8List.fromList(opaqueWriteToken));

    for (int i = 0; i < peerInfoStrings.length; i++) {
      if (!(peerInfoStrings[i] is Uint8List)) {
        peerInfoStrings[i] = new Uint8List.fromList(peerInfoStrings[i]);
      }
    }
    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId, "token": opaqueWriteToken, "values": peerInfoStrings}, "t": transactionId, "y": "r"});
  }

  static createResponseWithClosestNodes(List<int> transactionId, List<int> queryingNodesId, List<int> opaqueWriteToken, List<int> compactNodeInfo) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    opaqueWriteToken = (opaqueWriteToken is Uint8List ? opaqueWriteToken : new Uint8List.fromList(opaqueWriteToken));
    compactNodeInfo = (compactNodeInfo is Uint8List ? compactNodeInfo : new Uint8List.fromList(compactNodeInfo));

    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId, "nodes": compactNodeInfo, "token": opaqueWriteToken}, "t": transactionId, "y": "r"});
  }
}

class KrpcAnnounce {
  static int queryID = 0;
  static KrpcMessage createQuery(List<int> queryingNodesId, int implied_port, List<int> infoHash, int port, List<int> opaqueToken) {
    List<int> transactionId = UTF8.encode("an${queryID++}");
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    infoHash = (infoHash is Uint8List ? infoHash : new Uint8List.fromList(infoHash));
    opaqueToken = (opaqueToken is Uint8List ? opaqueToken : new Uint8List.fromList(opaqueToken));

    return new KrpcMessage.fromMap(
        {"a": {"id": queryingNodesId, "info_hash": infoHash, "implied_port": implied_port, "port": port, "token": opaqueToken}, "q": "announce_peer", "t": transactionId, "y": "q"});
  }

  static KrpcMessage createResponse(List<int> transactionId, List<int> queryingNodesId) {
    transactionId = (transactionId is Uint8List ? transactionId : new Uint8List.fromList(transactionId));
    queryingNodesId = (queryingNodesId is Uint8List ? queryingNodesId : new Uint8List.fromList(queryingNodesId));
    return new KrpcMessage.fromMap({"r": {"id": queryingNodesId}, "t": transactionId, "y": "r"});
  }
}
