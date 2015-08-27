library hetimatorrent.dht.knodeai.announce;

import 'dart:core';
import 'package:hetimanet/hetimanet.dart';
import '../kid.dart';

import '../message/krpcmessage.dart';
import '../message/krpcmessage_announce.dart';
import '../message/krpcmessage_getpeers.dart';
import '../kpeerinfo.dart';
import '../kgetpeervalue.dart';
import '../knode.dart';
import 'knodework.dart';
import 'knodework_announcetask.dart';

class KNodeWorkAnnounce extends KNodeWork {
  bool _isStart = false;
  bool get isStart => _isStart;
  Map<KId, KNodeWorkAnnounceTask> taskList = {};

  start(KNode node) {
    _isStart = true;
  }

  stop(KNode node) {
    _isStart = false;
  }

  updateP2PNetwork(KNode node) {
  }

  startSearchValue(KNode node, KId infoHash, int port, {getPeerOnly:false}) {
    if (infoHash != null) {
      if (false == taskList.containsKey(infoHash)) {
        taskList[infoHash] = new KNodeWorkAnnounceTask(infoHash, port);
      }
      taskList[infoHash].port = port;
    }
    researchSearchPeer(node, infoHash, getPeerOnly:getPeerOnly);
  }

  researchSearchPeer(KNode node, KId infoHash,{getPeerOnly:false}) {
    if (infoHash == null) {
      for(KNodeWorkAnnounceTask t in taskList.values) {
        if(t != null && t.isStart == true) { 
          t.startSearchPeer(node, infoHash, getPeerOnly:getPeerOnly);
        }
      }
    } else {
      if (true == taskList.containsKey(infoHash)) {
        taskList[infoHash].startSearchPeer(node, infoHash, getPeerOnly:getPeerOnly);
      }
    }
  }

  stopSearchValue(KNode node, KId infoHash) {
    if (true == taskList.containsKey(infoHash)) {
      taskList[infoHash].stopSearchPeer(node, infoHash);
    }
  }

  onTicket(KNode node) {
    for (KNodeWorkAnnounceTask t in taskList.values) {
      if (t.isStart) {
        t.onTicket(node);
      }
    }
  }

  onReceiveQuery(KNode node, HetimaReceiveUdpInfo info, KrpcMessage query) {

    for (KNodeWorkAnnounceTask t in taskList.values) {
      if (t.isStart) {
        t.onReceiveQuery(node, info, query);
      }
    }
    switch (query.queryAsString) {
      case KrpcMessage.MESSAGE_ANNOUNCE:
        {
          KrpcAnnounce announce = query.toAnnounce();
          List<int> opaqueWriteTokenA = node.getOpaqueWriteToken(announce.infoHashAsKId, announce.nodeIdAsKId);
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
            node.rawAnnounced.addLast(new KGetPeerValue.fromString(info.remoteAddress, announce.port, announce.infoHash));
          } else {
            node.rawAnnounced.addLast(new KGetPeerValue.fromString(info.remoteAddress, info.remotePort, announce.infoHash));            
          }
          return node.sendAnnouncePeerResponse(info.remoteAddress, info.remotePort, announce.transactionId).catchError((_){});
        }
        break;
      case KrpcMessage.MESSAGE_GET_PEERS:
        {
          KrpcGetPeers getpeers = query.toKrpcGetPeers();
          //print("## receive query");
          List<KGetPeerValue> target = node.rawAnnounced.getWithFilter((KGetPeerValue i) {
            List<int> a = i.infoHash.value;
            List<int> b = getpeers.infoHash;
            for (int i = 0; i < 20; i++) {
              if (a[i] != b[i]) {
                return false;
              }
            }
            return true;
          });
          List<int> opaqueWriteToken = node.getOpaqueWriteToken(getpeers.infoHashAsKId, getpeers.nodeIdAsKId);
          if (target.length > 0) {
            return node.sendGetPeersResponseWithPeers(info.remoteAddress, info.remotePort, getpeers.transactionId, opaqueWriteToken, KGetPeerValue.toPeerInfoStrings(target)).catchError((_){}); //todo
          } else {
            return node.rootingtable.findNode(getpeers.infoHashAsKId).then((List<KPeerInfo> infos) {
              return node.sendGetPeersResponseWithClosestNodes(info.remoteAddress, info.remotePort, getpeers.transactionId, opaqueWriteToken, KPeerInfo.toCompactNodeInfos(infos)).catchError((_){});
            });
          }
        }
        break;
    }
  }

  onReceiveResponse(KNode node, HetimaReceiveUdpInfo info, KrpcMessage response) {
    for (KNodeWorkAnnounceTask t in taskList.values) {
      if (t.isStart) {
        t.onReceiveResponse(node, info, response);
      }
    }
  }

  onReceiveError(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {}

  onReceiveUnknown(KNode node, HetimaReceiveUdpInfo info, KrpcMessage message) {}
  
  onAddNodeFromIPAndPort(KNode node, String ip, int port) {}
}
