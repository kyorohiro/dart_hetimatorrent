library hetimatorrent.dht.krpcannounce;

import 'dart:core';
import 'dart:async';
import '../../util/bencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcmessage.dart';
import 'dart:typed_data';
import 'dart:convert';

class KrpcAnnouncePeerQuery extends KrpcQuery {

  // find_node Query = {"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
  // bencoded = d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe
  KrpcAnnouncePeerQuery.fromString(String transactionIdAsString, String queryingNodesIdAsString, int implied_port, List<int> infoHash, int port, String opaqueTokenAsString) 
  :super(KrpcMessage.ANNOUNCE_QUERY) {
    List<int> transactionId = UTF8.encode(transactionIdAsString);
    List<int> queryingNodesId = UTF8.encode(queryingNodesIdAsString);
    List<int> opaqueToken = UTF8.encode(opaqueTokenAsString);
    rawMessageMap.addAll({
      "a": {"id": queryingNodesId, "info_hash": infoHash, "implied_port": implied_port, "port": port, "token": opaqueToken},
      "q": "announce_peer", 
      "t": transactionId,
      "y": "q"
      });
  }
  KrpcAnnouncePeerQuery(List<int> transactionId, List<int> queryingNodesId, int implied_port, List<int> infoHash, int port, List<int> opaqueToken) 
  :super(KrpcMessage.ANNOUNCE_QUERY){
    _init(transactionId, queryingNodesId, implied_port, infoHash, port, opaqueToken);
  }
  _init(List<int> transactionId, List<int> queryingNodesId, int implied_port, List<int> infoHash, int port, List<int> opaqueToken) {
    if(!(transactionId is Uint8List)) {
      transactionId = new Uint8List.fromList(transactionId);
    }
    if(!(queryingNodesId is Uint8List)) {
      queryingNodesId = new Uint8List.fromList(queryingNodesId);
    }
    if(!(infoHash is Uint8List)) {
      infoHash = new Uint8List.fromList(infoHash);
    }
    if(!(opaqueToken is Uint8List)) {
      opaqueToken = new Uint8List.fromList(opaqueToken);
    }
    
      rawMessageMap.addAll({
        "a": {"id": queryingNodesId, "info_hash": infoHash, "implied_port": implied_port, "port": port, "token": opaqueToken},
        "q": "announce_peer", 
        "t": transactionId,
        "y": "q"
        });
  }

  KrpcAnnouncePeerQuery.fromMap(Map<String, Object> messageAsMap) 
  :super(KrpcMessage.ANNOUNCE_QUERY){
    if (!KrpcQuery.queryCheck(messageAsMap, "announce_peer")) {
      throw {};
    }
    Map<String, Object> a = messageAsMap["a"];
    rawMessageMap.addAll({
      "a": {"id": a["id"], "info_hash": a["info_hash"], "implied_port": a["implied_port"], "port": a["port"], "token": a["token"]},
      "q": "announce_peer",
      "t": messageAsMap["t"],
      "y": "q"
    });
  }

  static Future<KrpcAnnouncePeerQuery> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      return new KrpcAnnouncePeerQuery.fromMap(v);
    });
  }
}

class KrpcAnnouncePeerResponse extends KrpcResponse {

  // Response with peers = {"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "values": ["axje.u", "idhtnm"]}}
  // bencoded = d1:rd2:id20:abcdefghij01234567895:token8:aoeusnth6:valuesl6:axje.u6:idhtnmee1:t2:aa1:y1:re
  KrpcAnnouncePeerResponse.fromString(String transactionIdAsString, String queryingNodesIdAsString)
  :super(KrpcMessage.ANNOUNCE_RESPONSE) {
    List<int> transactionId = UTF8.encode(transactionIdAsString);
    List<int> queryingNodesId = UTF8.encode(queryingNodesIdAsString);
    _init(transactionId, queryingNodesId);
  }
  KrpcAnnouncePeerResponse(List<int> transactionId, List<int> queryingNodesId)
  :super(KrpcMessage.ANNOUNCE_RESPONSE) {
    _init(transactionId, queryingNodesId);
  }

  _init(List<int> transactionId, List<int> queryingNodesId) {
    if(!(transactionId is Uint8List)) {
      transactionId = new Uint8List.fromList(transactionId);
    }
    if(!(queryingNodesId is Uint8List)) {
      queryingNodesId = new Uint8List.fromList(queryingNodesId);
    }
    rawMessageMap.addAll({
      "r": {"id": queryingNodesId}, 
      "t": transactionId,
      "y": "r"});
  }
  KrpcAnnouncePeerResponse.fromMap(Map<String, Object> messageAsMap) 
  :super(KrpcMessage.ANNOUNCE_RESPONSE) {
    if (!KrpcResponse.queryCheck(messageAsMap)) {
      throw {};
    }
    Map<String, Object> r = messageAsMap["r"];
    rawMessageMap.addAll({
      "r": {"id": r["id"]},
      "t": messageAsMap["t"],
      "y": "r"});
  }

  static Future<KrpcAnnouncePeerResponse> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      return new KrpcAnnouncePeerResponse.fromMap(v);
    });
  }
}
