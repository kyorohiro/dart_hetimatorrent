library hetimatorrent.dht.knodeai.announce;

import 'dart:core';
import 'package:hetimanet/hetimanet.dart';
import '../message/krpcgetpeers.dart';
import '../kid.dart';

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

  startSearchPeer(KNode node, KId infoHash, int port) {
    if (infoHash != null) {
      if (false == taskList.containsKey(infoHash)) {
        taskList[infoHash] = new KNodeAIAnnounceTask(infoHash, port);
      }
      taskList[infoHash].port = port;
    }
    researchSearchPeer(node, infoHash);
  }

  researchSearchPeer(KNode node, KId infoHash) {
    if (infoHash == null) {
      for(KNodeAIAnnounceTask t in taskList.values) {
        if(t != null && t.isStart == true) { 
          t.startSearchPeer(node, infoHash);
        }
      }
    } else {
      if (true == taskList.containsKey(infoHash)) {
        taskList[infoHash].startSearchPeer(node, infoHash);
      }
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
          List<int> opaqueWriteTokenA = node.getOpaqueWriteToken(new KId(announce.infoHash), announce.queryingNodesId);
          List<int> opaqueWriteTokenB = announce.token;
          if(opaqueWriteTokenA.length != opaqueWriteTokenB.length) {
            return{};
          }
          for(int i=0;i<opaqueWriteTokenA.length;i++) {
            if(opaqueWriteTokenA[i] != opaqueWriteTokenB[i]) {
              return {};
            }
          }
          if(announce.impliedPort == 0) {
            node.rawAnnounced.addLast(new KAnnounceInfo.fromString(info.remoteAddress, announce.port, announce.infoHash));
          } else {
            node.rawAnnounced.addLast(new KAnnounceInfo.fromString(info.remoteAddress, info.remotePort, announce.infoHash));            
          }
          return node.sendAnnouncePeerResponse(info.remoteAddress, info.remotePort, query.transactionId);
        }
        break;
      case KrpcMessage.GET_PEERS_QUERY:
        {
          //print("## receive query");
          KrpcGetPeersQuery getPeer = query;
          List<KAnnounceInfo> target = node.rawAnnounced.getWithFilter((KAnnounceInfo i) {
            List<int> a = i.infoHash.id;
            List<int> b = getPeer.infoHash;
            for (int i = 0; i < 20; i++) {
              if (a[i] != b[i]) {
                return false;
              }
            }
            return true;
          });
          List<int> opaqueWriteToken = node.getOpaqueWriteToken(new KId(getPeer.infoHash), getPeer.queryingNodesId);
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
  
  onAddNodeFromIPAndPort(KNode node, String ip, int port) {}
}
