library hetimatorrent.dht.knodeai;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../krootingtable.dart';

import '../message/krpcping.dart';
import '../message/krpcfindnode.dart';
import '../message/krpcgetpeers.dart';
import '../kid.dart';
import 'dart:convert';
import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../message/krpcping.dart';
import '../message/krpcfindnode.dart';
import '../message/krpcgetpeers.dart';
import '../message/krpcannounce.dart';
import '../kpeerinfo.dart';
import '../knode.dart';
import 'knodeaifindnode.dart';

abstract class KNodeAI {
  bool get isStart;
  start(KNode node);
  stop(KNode node);
  maintenance(KNode node);
  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query);
  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message);
  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response);
  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message);
}

class KNodeAIBasic extends KNodeAI {
  bool _isStart = false;
  bool get isStart => _isStart;

  KNodeAIFindNode findNodeAI = new KNodeAIFindNode();

  start(KNode node) {
    findNodeAI.start(node);
  }

  stop(KNode node) {
    findNodeAI.stop(node);
  }

  maintenance(KNode node) {
    findNodeAI.maintenance(node);
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    findNodeAI.onReceiveQuery(node, info, query);
  }

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message) {
    findNodeAI.onReceiveError(node, info, message);
  }

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response) {
    findNodeAI.onReceiveResponse(node, info, response);
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {
    findNodeAI.onReceiveUnknown(node, info, message);
  }
}

