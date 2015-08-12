library hetimatorrent.dht.knodeaibasic;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../krootingtable.dart';

import '../message/krpcfindnode.dart';
import '../message/krpcgetpeers.dart';
import '../kid.dart';
import 'dart:convert';
import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../message/krpcfindnode.dart';
import '../message/krpcgetpeers.dart';
import '../message/krpcannounce.dart';
import '../kpeerinfo.dart';
import '../knode.dart';
import 'knodeaifindnode.dart';
import 'knodeiannounce.dart';
import 'knodeai.dart';

class KNodeAIBasic extends KNodeAI {
  bool _isStart = false;
  bool get isStart => _isStart;

  KNodeAIFindNode findNodeAI = new KNodeAIFindNode();
  KNodeAIAnnounce announceAI = new KNodeAIAnnounce();

  KNodeAIBasic({bool verbose: false}) {}

  start(KNode node) {
    findNodeAI.start(node);
    announceAI.start(node);
  }

  stop(KNode node) {
    findNodeAI.stop(node);
    announceAI.stop(node);
  }

  updateP2PNetwork(KNode node) {
    findNodeAI.updateP2PNetwork(node);
    announceAI.updateP2PNetwork(node);
  }

  startSearchValue(KNode node, KId infoHash, int port, {getPeerOnly:false}) {
    return announceAI.startSearchValue(node, infoHash, port);
  }

  researchSearchPeer(KNode node, KId infoHash) {
    announceAI.researchSearchPeer(node, infoHash);
  }

  stopSearchValue(KNode node, KId infoHash) {
    announceAI.stopSearchValue(node, infoHash);
  }

  onTicket(KNode node) {
    findNodeAI.onTicket(node);
    announceAI.onTicket(node);
  }

  onAddNodeFromIPAndPort(KNode node, String ip, int port) {
    findNodeAI.onAddNodeFromIPAndPort(node, ip, port);
    announceAI.onAddNodeFromIPAndPort(node, ip, port);
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, query.queryingNodesId));
    switch (query.messageSignature) {
      case KrpcMessage.PING_QUERY:
        return node.sendPingResponse(info.remoteAddress, info.remotePort, query.transactionId).catchError((_){});
      case KrpcMessage.FIND_NODE_QUERY:
        break;
      case KrpcMessage.NONE_QUERY:
        return node.sendErrorResponse(info.remoteAddress, info.remotePort, KrpcError.METHOD_ERROR, query.transactionId).catchError((_){});
      case KrpcMessage.ANNOUNCE_QUERY:
        break;
      case KrpcMessage.GET_PEERS_QUERY:
        break;
    }
    findNodeAI.onReceiveQuery(node, info, query);
    announceAI.onReceiveQuery(node, info, query);
  }

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response) {
    findNodeAI.onReceiveResponse(node, info, response);
    announceAI.onReceiveResponse(node, info, response);
  }

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {
    findNodeAI.onReceiveError(node, info, message);
    announceAI.onReceiveError(node, info, message);
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {
    findNodeAI.onReceiveUnknown(node, info, message);
    announceAI.onReceiveUnknown(node, info, message);
  }
}
