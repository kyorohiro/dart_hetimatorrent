library hetimatorrent.dht.knodeai.findnode;

import 'dart:core';
import 'dart:async';
import 'package:hetimanet/hetimanet.dart';

import '../kid.dart';
import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../message/krpcmessage_builder.dart';
import '../kpeerinfo.dart';
import '../knode.dart';

class KNodeWorkFindNode {
  bool _isStart = false;
  List<List> _todoFineNodes = [];
  ShuffleLinkedList<KPeerInfo> _findNodesInfo = new ShuffleLinkedList(20);
  int startTime = 0;

  start(KNode node) {
    _isStart = true;
    startTime = new DateTime.now().millisecondsSinceEpoch;
    updateP2PNetwork(node);
  }

  stop(KNode node) {
    _isStart = false;
  }

  updateP2PNetwork(KNode node) {
    _findNodesInfo.clearAll();
    updateP2PNetworkWithoutClear(node);
  }

  updateP2PNetworkWithoutClear(KNode node) {
    node.rootingtable.findNode(node.nodeId).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      int count = 0;
      for (KPeerInfo info in infos) {
        if (!_findNodesInfo.rawsequential.contains(info)) {
          count++;
          _findNodesInfo.addLast(info);
          node.sendFindNodeQuery(info.ipAsString, info.port, node.nodeId.value).catchError((_) {});
          if (node.verbose == true) {
            print("<id_index>=${node.rootingtable.getRootingTabkeIndex(info.id)}");
          }
        }
        //
        // todo
        int currentTime = new DateTime.now().millisecondsSinceEpoch;
        if (currentTime - startTime > 30000 && count > 3) {
          break;
        } else if (currentTime - startTime > 5000 && count > 5) {
          break;
        }
      }
    });
  }
  updateP2PNetworkWithRandom(KNode node) {
    node.rootingtable.findNode(KId.createIDAtRandom()).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      int count = 0;
      for (KPeerInfo info in infos) {
        if (!_findNodesInfo.rawsequential.contains(info)) {
          count++;
          _findNodesInfo.addLast(info);
          node.sendFindNodeQuery(info.ipAsString, info.port, KId.createIDAtRandom().value);
        }
        if (count > 3) {
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

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcMessage query) {
    if (_isStart == false) {
      return null;
    }
    if (query.queryAsString == KrpcMessage.QUERY_FIND_NODE) {
      KrpcFindNode findNode = query.toFindNode();
      return node.rootingtable.findNode(findNode.targetAsKId).then((List<KPeerInfo> infos) {
        return node.sendFindNodeResponse(info.remoteAddress, info.remotePort, query.transactionId, KPeerInfo.toCompactNodeInfos(infos)).catchError((_) {});
      });
    }
    node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, query.nodeIdAsKId)).then((_) {
      return updateP2PNetworkWithoutClear(node);
    });
  }

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcMessage response) {
    new Future(() {
      if (_isStart == false) {
        return null;
      }
      if (response.queryFromTransactionId == KrpcMessage.QUERY_FIND_NODE) {
        KrpcFindNode findNode = response.toFindNode();
        List<KPeerInfo> peerInfo = findNode.compactNodeInfoAsKPeerInfo;
        List<Future> f = [];
        for (KPeerInfo info in peerInfo) {
          f.add(node.rootingtable.update(info));
        }
        return Future.wait(f);
      }
    }).then((e) {
      node.rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, response.nodeIdAsKId)).then((_) {
        return updateP2PNetworkWithoutClear(node);
      });
    });
  }

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
}
