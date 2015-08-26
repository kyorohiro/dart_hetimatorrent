library hetimatorrent.dht.knodeai.findnode;

import 'dart:core';
import 'package:hetimanet/hetimanet.dart';

import '../kid.dart';
import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../message/krpcmessage_findnode.dart';
import '../kpeerinfo.dart';
import '../knode.dart';

class KNodeWorkFindNode {
  List<List> _todoFineNodes = [];
  ShuffleLinkedList<KPeerInfo> _findNodesInfo = new ShuffleLinkedList(20);
  int startTime = 0;

  start(KNode node) {
    startTime = new DateTime.now().millisecondsSinceEpoch;
    updateP2PNetwork(node);
  }

  stop(KNode node) {
  }

  updateP2PNetwork(KNode node) {
    _findNodesInfo.clearAll();
    updateP2PNetworkWithoutClear(node);
  }

  updateP2PNetworkWithoutClear(KNode node) {
    node.rootingtable.findNode(node.nodeId).then((List<KPeerInfo> infos) {
      if (node.isStart== false) {
        return;
      }
      int count = 0;
      int currentTime = new DateTime.now().millisecondsSinceEpoch;
      for (KPeerInfo info in infos) {
        if (!_findNodesInfo.rawsequential.contains(info)) {
          count++;
          _findNodesInfo.addLast(info);
          node.sendFindNodeQuery(info.ipAsString, info.port, node.nodeId.value).catchError((_) {});
          node.log("<id_index>=${node.rootingtable.getRootingTabkeIndex(info.id)}");
        }
        //
        if (currentTime - startTime > 30000 && count > 2) {
          break;
        } else if (currentTime - startTime > 5000 && count > 5) {
          break;
        }
      }
    });
  }
  updateP2PNetworkWithRandom(KNode node) {
    node.rootingtable.findNode(KId.createIDAtRandom()).then((List<KPeerInfo> infos) {
      if (node.isStart== false) {
        return;
      }
      int count = 0;
      int currentTime = new DateTime.now().millisecondsSinceEpoch;
      for (KPeerInfo info in infos) {
        if (!_findNodesInfo.rawsequential.contains(info)) {
          count++;
          _findNodesInfo.addLast(info);
          node.sendFindNodeQuery(info.ipAsString, info.port, KId.createIDAtRandom().value);
        }
        //
        //
        if (currentTime - startTime > 30000 && count > 1) {
          break;
        } else if (currentTime - startTime > 5000 && count > 3) {
          break;
        }
      }
    });
  }

  onAddNodeFromIPAndPort(KNode node, String ip, int port) {
    if (node.rawUdoSocket != null) {
      node.sendFindNodeQuery(ip, port, node.nodeId.value).catchError((_) {});
    } else {
      _todoFineNodes.add([ip, port]);
    }
  }

  onTicket(KNode node) {
    updateP2PNetworkWithRandom(node);
    for (List l in _todoFineNodes) {
      node.sendFindNodeQuery(l[0], l[1], node.nodeId.value).catchError((_) {});
    }
    _todoFineNodes.clear();
  }

  onReceiveQuery(KNode node, HetimaReceiveUdpInfo info, KrpcMessage query) {
    if (query.queryAsString == KrpcMessage.QUERY_FIND_NODE) {
      KrpcFindNode findNode = query.toFindNode();
      return node.rootingtable.findNode(findNode.targetAsKId).then((List<KPeerInfo> infos) {
        return node.sendFindNodeResponse(info.remoteAddress, info.remotePort, query.transactionId, KPeerInfo.toCompactNodeInfos(infos)).catchError((_) {});
      });
    }
    node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, query.nodeIdAsKId));
    updateP2PNetworkWithoutClear(node);
  }

  onReceiveResponse(KNode node, HetimaReceiveUdpInfo info, KrpcMessage response) {
    if (response.queryFromTransactionId == KrpcMessage.QUERY_FIND_NODE) {
      KrpcFindNode findNode = response.toFindNode();
      for (KPeerInfo info in findNode.compactNodeInfoAsKPeerInfo) {
        node.rootingtable.update(info);
      }
    }
    node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, response.nodeIdAsKId));
    updateP2PNetworkWithoutClear(node);
  }

  onReceiveError(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {}
  onReceiveUnknown(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {}
}
