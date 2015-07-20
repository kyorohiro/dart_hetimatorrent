library hetimatorrent.dht.krpcannounce;

import 'dart:core';
import 'dart:async';
import '../util/bencode.dart';
import 'package:hetimacore/hetimacore.dart';
import 'krpcmessage.dart';

class KrpcAnnouncePeerQuery extends KrpcQuery {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);
  // find_node Query = {"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
  // bencoded = d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe
  KrpcAnnouncePeerQuery(String transactionId, String queryingNodesId, int implied_port, List<int> infoHash, int port, String opaqueToken) {
    _messageAsMap = {
      "a": {"id": queryingNodesId, "info_hash": infoHash, "implied_port": implied_port, "port": port, "token": opaqueToken},
      "q": "announce_peer", 
      "t": transactionId,
      "y": "q"
      };
  }

  KrpcAnnouncePeerQuery.fromMap(Map<String, Object> messageAsMap) {
    if (!KrpcQuery.queryCheck(messageAsMap, "announce_peer")) {
      throw {};
    }
    Map<String, Object> a = messageAsMap["a"];
    _messageAsMap = {
      "a": {"id": a["id"], "info_hash": a["info_hash"], "implied_port": a["implied_port"], "port": a["port"], "token": a["token"]},
      "q": "announce_peer",
      "t": messageAsMap["t"],
      "y": "q"
    };
  }

  static Future<KrpcAnnouncePeerQuery> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      return new KrpcAnnouncePeerQuery.fromMap(v);
    });
  }
}

class KrpcAnnouncePeerResponse extends KrpcResponse {
  Map<String, Object> _messageAsMap = null;
  Map<String, Object> get messageAsMap => new Map.from(_messageAsMap);
  List<int> get messageAsBencode => Bencode.encode(_messageAsMap);

  // Response with peers = {"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "values": ["axje.u", "idhtnm"]}}
  // bencoded = d1:rd2:id20:abcdefghij01234567895:token8:aoeusnth6:valuesl6:axje.u6:idhtnmee1:t2:aa1:y1:re
  KrpcAnnouncePeerResponse(String transactionId, String queryingNodesId) {
    _messageAsMap = {"r": {"id": queryingNodesId}, "t": transactionId, "y": "r"};
  }

  KrpcAnnouncePeerResponse.fromMap(Map<String, Object> messageAsMap) {
    if (!KrpcResponse.queryCheck(messageAsMap)) {
      throw {};
    }
    Map<String, Object> r = messageAsMap["r"];
    _messageAsMap = {"t": messageAsMap["t"], "y": "r", "r": {"id": r["id"]}};
  }

  static Future<KrpcAnnouncePeerResponse> decode(EasyParser parser) {
    return KrpcMessage.decodeTest(parser, (Object v) {
      return new KrpcAnnouncePeerResponse.fromMap(v);
    });
  }
}
