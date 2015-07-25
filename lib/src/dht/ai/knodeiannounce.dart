library hetimatorrent.dht.knodeai.announce;

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
import 'knodeai.dart';

class KNodeAIAnnounce {
  bool _isStart = false;
  ShuffleLinkedList<KPeerInfo> announceNodesInfo = new ShuffleLinkedList(20);
  KId _infoHashId = null;
  KId _tokenFilter = null;
  bool get isStart => _isStart;

  KNodeAIAnnounce(KId infoHashId, {KId tokenFilter: null}) {
    this._infoHashId = infoHashId;
    this._tokenFilter = new KId(new List.filled(20, 0xff));
  }

  start(KNode node) {
    _isStart = true;
  }

  stop(KNode node) {
    _isStart = false;
  }

  maintenance(node) {}

  search(KNode node) {
    announceNodesInfo.clearAll();
    node.rootingtable.findNode(_infoHashId).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      for (KPeerInfo info in infos) {
        announceNodesInfo.addLast(info);
        node.sendGetPeersQuery(info.ipAsString, info.port, _infoHashId.id).catchError((e) {});
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
      case KrpcMessage.FIND_NODE_QUERY:
      case KrpcMessage.NONE_QUERY:
        break;
      case KrpcMessage.ANNOUNCE_QUERY:
        break;
      case KrpcMessage.GET_PEERS_QUERY:
        {
          KrpcGetPeersQuery getPeer = query;
          List<KAnnounceInfo> target = node.announcePeerWithFilter((KAnnounceInfo i) {
            List<int> a = i.infoHash;
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
            return node.sendGetPeersResponseWithPeers(
                info.remoteAddress, info.remotePort, query.transactionId,
                opaqueWriteToken, KAnnounceInfo.toPeerInfoStrings(target));//todo
          } else {
            return node.rootingtable.findNode(query.queryingNodesId).then((List<KPeerInfo> infos) {
              return node.sendGetPeersResponseWithClosestNodes(info.remoteAddress, info.remotePort, query.transactionId, 
                  opaqueWriteToken, KPeerInfo.toCompactNodeInfos(infos));
            });
          }
        }
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
            if (!announceNodesInfo.sequential.contains(info)) {
              node.sendFindNodeQuery(info.ipAsString, info.port, node.nodeId.id).catchError((e) {});
            }
          }
        });
      });
    });
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
}
