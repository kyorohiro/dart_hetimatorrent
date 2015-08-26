library hetimatorrent.dht.krpcmessage.ping;

import 'dart:core';
import 'dart:convert';
import '../kid.dart';
import 'dart:typed_data';
import '../kpeerinfo.dart';
import '../kgetpeervalue.dart';
import 'krpcmessage.dart';


class KrpcPing  extends KrpcMessage{

  KrpcPing(KrpcMessage message) : super.fromMap(message.rawMessageAsMap) {
    
  }

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
