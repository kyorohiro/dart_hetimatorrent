library hetimatorrent.dht.krpcmessage.announce;

import 'dart:core';
import 'dart:convert';
import '../kid.dart';
import 'dart:typed_data';
import '../kpeerinfo.dart';
import '../kgetpeervalue.dart';
import 'krpcmessage.dart';


class KrpcAnnounce extends KrpcMessage{

  KrpcAnnounce(KrpcMessage message) : super.fromMap(message.rawMessageAsMap) {
    
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
  
  List<int> get infoHash {
    Map<String, Object> a = messageAsMap["a"];
    return a["info_hash"];
  }

  KId get infoHashAsKId => new KId(infoHash);

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
