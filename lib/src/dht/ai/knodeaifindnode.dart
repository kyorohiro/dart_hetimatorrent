library hetimatorrent.dht.knodeai.findnode;

import 'dart:core';
import 'dart:async';
import 'package:hetimanet/hetimanet.dart';

import '../message/krpcfindnode.dart';
import '../kid.dart';
import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../kpeerinfo.dart';
import '../knode.dart';

class KNodeAIFindNode {
  bool _isStart = false;
  ShuffleLinkedList<KPeerInfo> findNodesInfo = new ShuffleLinkedList(20);

  start(KNode node) {
    _isStart = true;
    updateP2PNetwork(node);
  }

  stop(KNode node) {
    _isStart = false;
  }

  updateP2PNetwork(KNode node) {
    findNodesInfo.clearAll();
    updateP2PNetworkWithoutClear(node);
  }

  updateP2PNetworkWithoutClear(KNode node) {
    node.rootingtable.findNode(node.nodeId).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      for (KPeerInfo info in infos) {
        if (!findNodesInfo.rawsequential.contains(info)) {
          findNodesInfo.addLast(info);
          node.sendFindNodeQuery(info.ipAsString, info.port, node.nodeId.id);
        }
      }
    });
  }
  updateP2PNetworkWithRandom(KNode node) {
    node.rootingtable.findNode(node.nodeId.xor(KId.createIDAtRandom())).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      for (KPeerInfo info in infos) {
        if (!findNodesInfo.rawsequential.contains(info)) {
          findNodesInfo.addLast(info);
          node.sendFindNodeQuery(info.ipAsString, info.port, KId.createIDAtRandom().id);
        }
      }
    });
  }

  List mustTofindNode = [];
  onAddNodeFromIPAndPort(KNode node, String ip, int port) {
    if (node.rawUdoSocket != null) {
      node.sendFindNodeQuery(ip, port, node.nodeId.id);
    } else {
      mustTofindNode.add([ip, port]);
    }
  }

  onTicket(KNode node) {
    updateP2PNetworkWithRandom(node);
    for (List l in mustTofindNode) {
      node.sendFindNodeQuery(l[0], l[1], node.nodeId.id);
    }
    mustTofindNode.clear();
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    if (_isStart == false) {
      return null;
    }
    switch (query.messageSignature) {
      case KrpcMessage.FIND_NODE_QUERY:
        return node.rootingtable.findNode(query.queryingNodesId).then((List<KPeerInfo> infos) {
          return node.sendFindNodeResponse(info.remoteAddress, info.remotePort, query.transactionId, KPeerInfo.toCompactNodeInfos(infos));
        });
    }
    node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, query.queryingNodesId)).then((_) {
      return updateP2PNetworkWithoutClear(node);
    });
  }

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message) {}

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response) {
    new Future(() {
      if (_isStart == false) {
        return null;
      }
      if (response.messageSignature == KrpcMessage.FIND_NODE_RESPONSE) {
        KrpcFindNodeResponse findNode = response;
        List<KPeerInfo> peerInfo = findNode.compactNodeInfoAsKPeerInfo;
        List<Future> f = [];
        for (KPeerInfo info in peerInfo) {
          f.add(node.rootingtable.update(info));
        }
        return Future.wait(f);
      }
    }).then((e) {
      node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, response.queriedNodesId)).then((_) {
        return updateP2PNetworkWithoutClear(node);
      });
    });
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
}
