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
  ShuffleLinkedList<KPeerInfo> findNodesInfo = new ShuffleLinkedList(20);

  start(KNode node) {}

  stop(KNode node) {}

  maintenance(KNode node) {}

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {}

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message) {}

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response) {}

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
}
class KNodeAIFindNode {
  bool _isStart = false;
  ShuffleLinkedList<KPeerInfo> findNodesInfo = new ShuffleLinkedList(20);

  start(KNode node) {
    _isStart = true;
    maintenance(node);
  }

  stop(KNode node) {
    _isStart = false;
  }

  maintenance(KNode node) {
    findNodesInfo.clearAll();
    node.rootingtable.findNode(node.nodeId).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      for (KPeerInfo info in infos) {
        findNodesInfo.addLast(info);
        node.sendFindNodeQuery(info.ipAsString, info.port, node.nodeId.id);
      }
    });
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    if (_isStart == false) {
      return null;
    }
    node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, query.queryingNodesId));
    switch (query.messageSignature) {
      case KrpcMessage.PING_QUERY:
        return node.sendPingResponse(info.remoteAddress, info.remotePort, query.transactionId);
      case KrpcMessage.FIND_NODE_QUERY:
        return node.rootingtable.findNode(query.queryingNodesId).then((List<KPeerInfo> infos) {
          return node.sendFindNodeResponse(info.remoteAddress, info.remotePort, query.transactionId, KPeerInfo.toCompactNodeInfos(infos));
        });
      case KrpcMessage.NONE_QUERY:
        return node.sendErrorResponse(info.remoteAddress, info.remotePort, KrpcError.METHOD_ERROR, query.transactionId);
      case KrpcMessage.ANNOUNCE_QUERY:
        break;
      case KrpcMessage.GET_PEERS_QUERY:
        break;
    }
  }

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message) {}

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response) {
    new Future(() {
      if (_isStart == false) {
        return null;
      }
      node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, response.queriedNodesId));
      switch (response.messageSignature) {
        case KrpcMessage.PING_RESPONSE:
          break;
        case KrpcMessage.FIND_NODE_RESPONSE:
          {
            KrpcFindNodeResponse findNode = response;
            List<KPeerInfo> peerInfo = findNode.compactNodeInfoAsKPeerInfo;
            List<Future> f = [];
            for (KPeerInfo info in peerInfo) {
              f.add(node.rootingtable.update(info));
            }
            return Future.wait(f);
          }
          break;
        case KrpcMessage.NONE_RESPONSE:
          break;
        case KrpcMessage.ANNOUNCE_RESPONSE:
          break;
        case KrpcMessage.GET_PEERS_RESPONSE:
          break;
        default:
          break;
      }
    }).then((e) {
      if (_isStart == false) {
        return null;
      }
      node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, response.queriedNodesId)).then((_) {
        return node.rootingtable.findNode(node.nodeId).then((List<KPeerInfo> infos) {
          for (KPeerInfo info in infos) {
            if (!findNodesInfo.sequential.contains(info)) {
              node.sendFindNodeQuery(info.ipAsString, info.port, node.nodeId.id).catchError((e) {});
            }
          }
        });
      });
    });
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
}

