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
  ShuffleLinkedList<KPeerInfo> _findedNode = new ShuffleLinkedList(50);
  List<KAnnounceInfo> announcedNode = [];
  KId _infoHashId = null;
  KId _tokenFilter = null;
  bool get isStart => _isStart;
  int lastUpdateTime = 0;

  KNodeAIAnnounce(KId infoHashId, {KId tokenFilter: null}) {
    this._infoHashId = infoHashId;
    this._tokenFilter = new KId(new List.filled(20, 0xff));
  }

  start(KNode node) {
    _isStart = true;
    lastUpdateTime = 0;
  }

  stop(KNode node) {
    _isStart = false;
  }

  maintenance(node) {}

  search(KNode node) {
    _findedNode.clearAll();
    node.rootingtable.findNode(_infoHashId).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      for (KPeerInfo info in infos) {
        _findedNode.addLast(info);
        node.sendGetPeersQuery(info.ipAsString, info.port, _infoHashId.id).catchError((e) {});
      }
    });
  }

  onTicket(KNode node) {
    if (lastUpdateTime == 0) {
      return;
    }

    int t = new DateTime.now().millisecondsSinceEpoch;
    if (t - lastUpdateTime > 5000) {
      announcedNode.sort((KAnnounceInfo a, KAnnounceInfo b) {
        if (a.infoHash == b.infoHash) {
          return 0;
        } else if (a.infoHash > b.infoHash) {
          return 1;
        } else {
          return -1;
        }
      });
      while (8 < announcedNode.length) {
        announcedNode.removeAt(10);
      }
      for(KAnnounceInfo i in announcedNode) {
        node.sendAnnouncePeerQuery(i.ipAsString, i.port, 1, _infoHashId.id, i.token.id);
      }
    }
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    if (_isStart == false) {
      return null;
    }
    switch (query.messageSignature) {
      case KrpcMessage.PING_QUERY:
      case KrpcMessage.FIND_NODE_QUERY:
      case KrpcMessage.NONE_QUERY:
        break;
      case KrpcMessage.ANNOUNCE_QUERY:
        {
          return node.sendAnnouncePeerResponse(info.remoteAddress, info.remotePort, query.transactionId);
        }
        break;
      case KrpcMessage.GET_PEERS_QUERY:
        {
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
          break;
        case KrpcMessage.NONE_RESPONSE:
          break;
        case KrpcMessage.ANNOUNCE_RESPONSE:
          break;
        case KrpcMessage.GET_PEERS_RESPONSE:
          {
            KrpcGetPeersResponse getPeer = response;
            announcedNode.add(new KAnnounceInfo.fromString(info.remoteAddress, info.remotePort, _infoHashId.id)..token = getPeer.tokenAsKId);
            if (getPeer.haveValue == true) {
              for (KAnnounceInfo i in getPeer.valuesAsKAnnounceInfo(_infoHashId.id)) {
                node.addAnnounceInfoForSearchResult(i);
              }
            } else {
              List<KPeerInfo> candidate = [];
              for (KPeerInfo info in getPeer.compactNodeInfoAsKPeerInfo) {
                if (false == _findedNode.rawsequential.contains(info)) {
                  candidate.add(info);
                  _findedNode.addLast(info);
                  _findedNode.rawshuffled.sort((KPeerInfo a, KPeerInfo b) {
                    if (a.id == b.id) {
                      return 0;
                    } else if (a.id > b.id) {
                      return 1;
                    } else {
                      return -1;
                    }
                  });
                }
                for (int i = 0; i < 8 && i < _findedNode.length; i++) {
                  KPeerInfo info = _findedNode.rawshuffled[i];
                  if (true == candidate.contains(info)) {
                    lastUpdateTime = new DateTime.now().millisecondsSinceEpoch;
                    node.sendGetPeersQuery(info.ipAsString, info.port, _infoHashId.id);
                  }
                }
              }
              //
              //

            }
          }
          break;
        default:
          break;
      }
    });
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
}
