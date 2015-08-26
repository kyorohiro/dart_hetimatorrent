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
  int _startTime = 0;
  int get startTime => _startTime;

  start(KNode node) {
    _startTime = new DateTime.now().millisecondsSinceEpoch;
    updateP2PNetwork(node);
  }

  stop(KNode node) {}

  updateP2PNetwork(KNode node) {
    _findNodesInfo.clearAll();
    updateP2PNetworkWithoutClear(node);
  }

  updateP2PNetworkWithoutClear(KNode node) async {
    List<KPeerInfo> infos = await node.rootingtable.findNode(node.nodeId);
    int count = 0;
    int currentTime = new DateTime.now().millisecondsSinceEpoch;
    for (KPeerInfo info in infos) {
      if (currentTime - _startTime > 30000 && count > 2) {
        break;
      } else if (currentTime - _startTime > 5000 && count > 5) {
        break;
      }

      if (!_findNodesInfo.rawsequential.contains(info)) {
        count++;
        _findNodesInfo.addLast(info);
        node.sendFindNodeQuery(info.ipAsString, info.port, node.nodeId.value).catchError((_) {});
        node.log("<id_index>=${node.rootingtable.getRootingTabkeIndex(info.id)}");
      }
      //
    }
  }

  updateP2PNetworkWithRandom(KNode node) async {
    List<KPeerInfo> infos = await node.rootingtable.findNode(KId.createIDAtRandom());
    int count = 0;
    int currentTime = new DateTime.now().millisecondsSinceEpoch;
    for (KPeerInfo info in infos) {
      if (currentTime - _startTime > 30000 && count > 1) {
        break;
      } else if (currentTime - _startTime > 5000 && count > 3) {
        break;
      }

      if (!_findNodesInfo.rawsequential.contains(info)) {
        count++;
        _findNodesInfo.addLast(info);
        node.sendFindNodeQuery(info.ipAsString, info.port, KId.createIDAtRandom().value);
      }
    }
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

  updateyRootingTable(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) async {
    node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, message.nodeIdAsKId));
    updateP2PNetworkWithoutClear(node);
  }

  onReceiveQuery(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) async {
    if (message.queryAsString == KrpcMessage.QUERY_FIND_NODE) {
      KrpcFindNode findNode = message.toFindNode();
      List<KPeerInfo> infos = await node.rootingtable.findNode(findNode.targetAsKId);
      await node.sendFindNodeResponse(info.remoteAddress, info.remotePort, message.transactionId, KPeerInfo.toCompactNodeInfos(infos)).catchError((_) {});
    }
    updateyRootingTable(node, info, message);
  }

  onReceiveResponse(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {
    if (message.queryFromTransactionId == KrpcMessage.QUERY_FIND_NODE) {
      KrpcFindNode findNode = message.toFindNode();
      for (KPeerInfo info in findNode.compactNodeInfoAsKPeerInfo) {
        node.rootingtable.update(info);
      }
    }
    updateyRootingTable(node, info, message);
  }

  onReceiveError(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {}
  onReceiveUnknown(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {}
}
