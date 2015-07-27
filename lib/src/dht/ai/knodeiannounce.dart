library hetimatorrent.dht.knodeai.announce;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../message/krpcgetpeers.dart';
import '../kid.dart';
import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../message/krpcannounce.dart';
import '../kpeerinfo.dart';
import '../knode.dart';
import 'knodeai.dart';
import 'knodeiannouncetask.dart';

class KNodeAIAnnounce extends KNodeAI {
  bool _isStart = false;
  bool get isStart => _isStart;
  Map<KId, KNodeAIAnnounceTask> taskList = {};
  start(KNode node) {
    _isStart = true;
  }

  stop(KNode node) {
    _isStart = false;
  }

  updateP2PNetwork(KNode node) {
  }

  startSearchPeer(KNode node, KId infoHash) {
    if (infoHash == null) {
      for(KNodeAIAnnounceTask t in taskList.values) {
        if(t != null && t.isStart == true) { 
          t.startSearchPeer(node, infoHash);
        }
      }
    } else {
      if (false == taskList.containsKey(infoHash)) {
        taskList[infoHash] = new KNodeAIAnnounceTask(infoHash);
      }
      taskList[infoHash].startSearchPeer(node, infoHash);
    }
  }

  stopSearchPeer(KNode node, KId infoHash) {
    if (true == taskList.containsKey(infoHash)) {
      taskList[infoHash].stopSearchPeer(node, infoHash);
    }
  }

  onTicket(KNode node) {
    for (KNodeAIAnnounceTask t in taskList.values) {
      if (t.isStart) {
        t.onTicket(node);
      }
    }
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    for (KNodeAIAnnounceTask t in taskList.values) {
      if (t.isStart) {
        t.onReceiveQuery(node, info, query);
      }
    }
    switch (query.messageSignature) {
      case KrpcMessage.ANNOUNCE_QUERY:
        {
          KrpcAnnouncePeerQuery announce = query;
          node.addAnnouncePeerWithFilter(new KAnnounceInfo.fromString(info.remoteAddress, info.remotePort, announce.infoHash));
          return node.sendAnnouncePeerResponse(info.remoteAddress, info.remotePort, query.transactionId);
        }
        break;
      case KrpcMessage.GET_PEERS_QUERY:
        {
          //print("## receive query");
          KrpcGetPeersQuery getPeer = query;
          List<KAnnounceInfo> target = node.rawAnnouncedPeer.getWithFilter((KAnnounceInfo i) {
            List<int> a = i.infoHash.id;
            List<int> b = getPeer.infoHash;
            for (int i = 0; i < 20; i++) {
              if (a[i] != b[i]) {
                return false;
              }
            }
            return true;
          });
          List<int> opaqueWriteToken = KId.createToken(new KId(getPeer.infoHash), getPeer.queryingNodesId, node.nodeId);
          if (target.length > 0) {
            return node.sendGetPeersResponseWithPeers(info.remoteAddress, info.remotePort, query.transactionId, opaqueWriteToken, KAnnounceInfo.toPeerInfoStrings(target)); //todo
          } else {
            return node.rootingtable.findNode(query.queryingNodesId).then((List<KPeerInfo> infos) {
              return node.sendGetPeersResponseWithClosestNodes(info.remoteAddress, info.remotePort, query.transactionId, opaqueWriteToken, KPeerInfo.toCompactNodeInfos(infos));
            });
          }
        }
        break;
    }
  }

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response) {
    for (KNodeAIAnnounceTask t in taskList.values) {
      if (t.isStart) {
        t.onReceiveResponse(node, info, response);
      }
    }
  }

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message) {}

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
}
