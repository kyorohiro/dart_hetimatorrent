library hetimatorrent.dht.krpcmessage.response;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import '../../util/bencode.dart';
import '../kid.dart';
import 'dart:typed_data';
import '../message/krpcmessage_announce.dart';
import '../message/krpcmessage_ping.dart';
import '../message/krpcmessage_findnode.dart';
import '../message/krpcmessage_getpeers.dart';
import '../message/krpcmessage.dart';

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
