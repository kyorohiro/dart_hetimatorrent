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

  maintenance(KNode node) {
    ;
  }

  startSearchPeer(KNode node, KId infoHash) {
    if (false == taskList.containsKey(infoHash)) {
      taskList[infoHash] = new KNodeAIAnnounceTask(infoHash);
    }
    print("## start");
    taskList[infoHash].startSearchPeer(node, infoHash);
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
          return node.sendAnnouncePeerResponse(info.remoteAddress, info.remotePort, query.transactionId);
        }
        break;
      case KrpcMessage.GET_PEERS_QUERY:
        {
        print("## receive query");
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

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message) {
    for (KNodeAIAnnounceTask t in taskList.values) {
      if (t.isStart) {
        t.onReceiveError(node, info, message);
      }
    }
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {
    for (KNodeAIAnnounceTask t in taskList.values) {
      if (t.isStart) {
        t.onReceiveUnknown(node, info, message);
      }
    }
  }
}

class KNodeAIAnnounceTask {
  bool _isStart = false;
  ShuffleLinkedList<KPeerInfo> _findedNode = new ShuffleLinkedList(50);
  List<KAnnounceInfo> announcedNode = [];
  KId _infoHashId = null;
  bool get isStart => _isStart;
  int lastUpdateTime = 0;

  KNodeAIAnnounceTask(KId infoHashId) {
    this._infoHashId = infoHashId;
  }

  startSearchPeer(KNode node, KId infoHash) {
    _isStart = true;
    lastUpdateTime = 0;
    _search(node);
  }

  stopSearchPeer(KNode node, KId infoHash) {
    _isStart = false;
  }

  _search(KNode node) {
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
        } else if (a.infoHash.xor(_infoHashId) > b.infoHash.xor(_infoHashId)) {
          return 1;
        } else {
          return -1;
        }
      });
      print("###########announce -----${announcedNode.length}");
      while (8 < announcedNode.length) {
        announcedNode.removeAt(10);
      }
      for (KAnnounceInfo i in announcedNode) {
        node.sendAnnouncePeerQuery(i.ipAsString, i.port, 1, _infoHashId.id, i.token.id);
      }
    }
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    if (_isStart == false) {
      return null;
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
        case KrpcMessage.GET_PEERS_RESPONSE:
          {
          print("## response query");

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
                    } else if (a.id.xor(_infoHashId) > b.id.xor(_infoHashId)) {
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
      }
    });
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {}
}
