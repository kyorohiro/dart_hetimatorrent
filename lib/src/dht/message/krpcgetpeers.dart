library hetimatorrent.dht.krpgetpeers;

import 'dart:core';
import 'dart:async';
import '../../util/bencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcmessage.dart';
import 'dart:typed_data';
import 'dart:convert';

class KrpcGetPeersQuery extends KrpcQuery {
  //find_node Query = {"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
  //bencoded = d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe

  KrpcGetPeersQuery.fromString(String transactionIdAsString, String queryingNodesIdAsString, List<int> infoHash)
  :super(KrpcMessage.GET_PEERS_QUERY) {
    List<int> transactionId = UTF8.encode(transactionIdAsString);
    List<int> queryingNodesId = UTF8.encode(queryingNodesIdAsString);
    _init(transactionId, queryingNodesId, infoHash);
  }
  KrpcGetPeersQuery(List<int> transactionId, List<int> queryingNodesId, List<int> infoHash)
  :super(KrpcMessage.GET_PEERS_QUERY){
    _init(transactionId, queryingNodesId, infoHash);
  }

  _init(List<int> transactionId, List<int> queryingNodesId, List<int> infoHash) {
    if (!(transactionId is Uint8List)) {
      transactionId = new Uint8List.fromList(transactionId);
    }
    if (!(queryingNodesId is Uint8List)) {
      queryingNodesId = new Uint8List.fromList(queryingNodesId);
    }
    if (!(infoHash is Uint8List)) {
      infoHash = new Uint8List.fromList(infoHash);
    }
    rawMessageMap.addAll({"a": {"id": queryingNodesId, "info_hash": infoHash}, "q": "get_peers", "t": transactionId, "y": "q"});
  }
  KrpcGetPeersQuery.fromMap(Map<String, Object> messageAsMap)
  :super(KrpcMessage.GET_PEERS_QUERY){
    if (!KrpcQuery.queryCheck(messageAsMap, "get_peers")) {
      throw {};
    }
    Map<String, Object> a = messageAsMap["a"];
    rawMessageMap.addAll({"a": {"id": a["id"], "info_hash": a["info_hash"]}, "q": "get_peers", "t": messageAsMap["t"], "y": "q"});
  }

  static Future<KrpcGetPeersQuery> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      return new KrpcGetPeersQuery.fromMap(v);
    });
  }
}

class KrpcGetPeersResponse extends KrpcResponse {
  // Response with peers = {"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "values": ["axje.u", "idhtnm"]}}
  // bencoded = d1:rd2:id20:abcdefghij01234567895:token8:aoeusnth6:valuesl6:axje.u6:idhtnmee1:t2:aa1:y1:re
  KrpcGetPeersResponse.withPeersFromString(String transactionIdAsString, String queryingNodesIdAsString, String opaqueWriteTokenAsString, List<String> peerInfoStringsAsString) 
  :super(KrpcMessage.GET_PEERS_RESPONSE){
    List<int> transactionId = UTF8.encode(transactionIdAsString);
    List<int> queryingNodesId = UTF8.encode(queryingNodesIdAsString);
    List<int> opaqueWriteToken = UTF8.encode(opaqueWriteTokenAsString);
    List<List<int>> peerInfoStrings = [];
    for (int i = 0; i < peerInfoStringsAsString.length; i++) {
      peerInfoStrings.add(UTF8.encode(peerInfoStringsAsString[i]));
    }
    _initWithPeers(transactionId, queryingNodesId, opaqueWriteToken, peerInfoStrings);
  }

  KrpcGetPeersResponse.withPeers(List<int> transactionId, List<int> queryingNodesId, List<int> opaqueWriteToken, List<List<int>> peerInfoStrings) 
  :super(KrpcMessage.GET_PEERS_RESPONSE){
    _initWithPeers(transactionId, queryingNodesId, opaqueWriteToken, peerInfoStrings);
  }

  _initWithPeers(List<int> transactionId, List<int> queryingNodesId, List<int> opaqueWriteToken, List<List<int>> peerInfoStrings) {
    if (!(transactionId is Uint8List)) {
      transactionId = new Uint8List.fromList(transactionId);
    }
    if (!(queryingNodesId is Uint8List)) {
      queryingNodesId = new Uint8List.fromList(queryingNodesId);
    }
    if (!(opaqueWriteToken is Uint8List)) {
      opaqueWriteToken = new Uint8List.fromList(opaqueWriteToken);
    }
    for (int i = 0; i < peerInfoStrings.length; i++) {
      if (!(peerInfoStrings[i] is Uint8List)) {
        peerInfoStrings[i] = new Uint8List.fromList(peerInfoStrings[i]);
      }
    }
    rawMessageMap.addAll({"r": {"id": queryingNodesId, "token": opaqueWriteToken, "values": peerInfoStrings}, "t": transactionId, "y": "r"});
  }

  // Response with closest nodes = {"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "nodes": "def456..."}}
  // bencoded = d1:rd2:id20:abcdefghij01234567895:nodes9:def456...5:token8:aoeusnthe1:t2:aa1:y1:re
  KrpcGetPeersResponse.withClosestNodesFromString(String transactionIdAsString, String queryingNodesIdAsString, 
      String opaqueWriteTokenAsString, List<int> compactNodeInfo) 
    :super(KrpcMessage.GET_PEERS_RESPONSE) {
    List<int> transactionId = UTF8.encode(transactionIdAsString);
    List<int> queryingNodesId = UTF8.encode(queryingNodesIdAsString);
    List<int> opaqueWriteToken = UTF8.encode(opaqueWriteTokenAsString);
    _initWithClosestNodes(transactionId, queryingNodesId, opaqueWriteToken, compactNodeInfo);
  }
  
  KrpcGetPeersResponse.withClosestNodes(List<int> transactionId, List<int> queryingNodesId, List<int> opaqueWriteToken, List<int> compactNodeInfo)
  :super(KrpcMessage.GET_PEERS_RESPONSE) {
    _initWithClosestNodes(transactionId, queryingNodesId, opaqueWriteToken, compactNodeInfo);
  }
  _initWithClosestNodes(List<int> transactionId, List<int> queryingNodesId, List<int> opaqueWriteToken, List<int> compactNodeInfo) {
    if (!(transactionId is Uint8List)) {
      transactionId = new Uint8List.fromList(transactionId);
    }
    if (!(queryingNodesId is Uint8List)) {
      queryingNodesId = new Uint8List.fromList(queryingNodesId);
    }
    if (!(opaqueWriteToken is Uint8List)) {
      opaqueWriteToken = new Uint8List.fromList(opaqueWriteToken);
    }
    if (!(compactNodeInfo is Uint8List)) {
      compactNodeInfo = new Uint8List.fromList(compactNodeInfo);
    }
    rawMessageMap.addAll({"r": {"id": queryingNodesId, "nodes": compactNodeInfo, "token": opaqueWriteToken}, "t": transactionId, "y": "r"});
  }

  KrpcGetPeersResponse.FromMap(Map<String, Object> messageAsMap) 
  :super(KrpcMessage.GET_PEERS_RESPONSE) {
    if (((messageAsMap)["r"] as Map).containsKey("values") == true) {
      _initWithPeersFromMap(messageAsMap);
    } else {
      _initWithClosestNodesFromMap(messageAsMap);
    }
  }

  KrpcGetPeersResponse.withPeersFromMap(Map<String, Object> messageAsMap) 
  :super(KrpcMessage.GET_PEERS_RESPONSE) {
    _initWithPeersFromMap(messageAsMap);
  }

  _initWithPeersFromMap(Map<String, Object> messageAsMap) {
    if (!KrpcResponse.queryCheck(messageAsMap)) {
      throw {};
    }
    Map<String, Object> r = messageAsMap["r"];
    rawMessageMap.addAll({"r": {"id": r["id"], "token": r["token"], "values": r["values"]}, "t": messageAsMap["t"], "y": "r"});
  }

  KrpcGetPeersResponse.withClosestNodesFromMap(Map<String, Object> messageAsMap)
  :super(KrpcMessage.GET_PEERS_RESPONSE) {
    _initWithClosestNodesFromMap(messageAsMap);
  }
  _initWithClosestNodesFromMap(Map<String, Object> messageAsMap) {
    if (!KrpcResponse.queryCheck(messageAsMap)) {
      throw {};
    }
    Map<String, Object> r = messageAsMap["r"];
    rawMessageMap.addAll({"r": {"id": r["id"], "nodes": r["nodes"], "token": r["token"]}, "t": messageAsMap["t"], "y": "r"});
  }

  static Future<KrpcGetPeersResponse> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      if (!KrpcResponse.queryCheck(v)) {
        throw {};
      }
      if (((v as Map)["r"] as Map).containsKey("values") == true) {
        return new KrpcGetPeersResponse.withPeersFromMap(v);
      } else {
        return new KrpcGetPeersResponse.withClosestNodesFromMap(v);
      }
    });
  }
}
