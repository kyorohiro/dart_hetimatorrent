library hetimatorrent.dht.work.basic;

import 'dart:core';
import 'package:hetimanet/hetimanet.dart';

import '../kid.dart';
import '../message/krpcmessage.dart';
import '../kpeerinfo.dart';
import '../knode.dart';
import 'knodework_findnode.dart';
import 'knodework_announce.dart';
import 'knodework.dart';

class KNodeWorkBasic extends KNodeWork {
  KNodeWorkFindNode _findNodeAI = new KNodeWorkFindNode();
  KNodeWorkAnnounce _announceAI = new KNodeWorkAnnounce();

  KNodeWorkBasic({bool verbose: false}) {}

  start(KNode node) {
    _findNodeAI.start(node);
    _announceAI.start(node);
  }

  stop(KNode node) {
    _findNodeAI.stop(node);
    _announceAI.stop(node);
  }

  updateP2PNetwork(KNode node) {
    _findNodeAI.updateP2PNetwork(node);
    _announceAI.updateP2PNetwork(node);
  }

  startSearchValue(KNode node, KId infoHash, int port, {getPeerOnly: false}) {
    return _announceAI.startSearchValue(node, infoHash, port);
  }

  researchSearchPeer(KNode node, KId infoHash) {
    _announceAI.researchSearchPeer(node, infoHash);
  }

  stopSearchValue(KNode node, KId infoHash) {
    _announceAI.stopSearchValue(node, infoHash);
  }

  onTicket(KNode node) {
    _findNodeAI.onTicket(node);
    _announceAI.onTicket(node);
  }

  onAddNodeFromIPAndPort(KNode node, String ip, int port) {
    _findNodeAI.onAddNodeFromIPAndPort(node, ip, port);
    _announceAI.onAddNodeFromIPAndPort(node, ip, port);
  }

  onReceiveQuery(KNode node, HetimaReceiveUdpInfo info, KrpcMessage query) {
    if (node.isStart  == false) {
      return null;
    }
    node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, query.nodeIdAsKId));
    switch (query.queryAsString) {
      case KrpcMessage.MESSAGE_PING:
        return node.sendPingResponse(info.remoteAddress, info.remotePort, query.transactionId).catchError((_) {});
      case KrpcMessage.MESSAGE_FIND_NODE:
      case KrpcMessage.MESSAGE_ANNOUNCE:
      case KrpcMessage.MESSAGE_GET_PEERS:
        break;
      default:
        return node.sendErrorResponse(info.remoteAddress, info.remotePort, KrpcMessage.METHOD_ERROR, query.transactionId).catchError((_) {});
    }
    _findNodeAI.onReceiveQuery(node, info, query);
    _announceAI.onReceiveQuery(node, info, query);
  }

  onReceiveResponse(KNode node, HetimaReceiveUdpInfo info, KrpcMessage response) {
    if (node.isStart == false) {
      return null;
    }
    _findNodeAI.onReceiveResponse(node, info, response);
    _announceAI.onReceiveResponse(node, info, response);
  }

  onReceiveError(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {
    if (node.isStart  == false) {
      return null;
    }
    _findNodeAI.onReceiveError(node, info, message);
    _announceAI.onReceiveError(node, info, message);
  }

  onReceiveUnknown(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {
    if (node.isStart  == false) {
      //return null;
    }
    _findNodeAI.onReceiveUnknown(node, info, message);
    _announceAI.onReceiveUnknown(node, info, message);
  }
}
