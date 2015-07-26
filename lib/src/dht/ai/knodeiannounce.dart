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
  List<KGetPeerInfo> receiveGetPeerResponseNode = [];
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
      _requestAnnounce(node);
      _search(node);
    }
  }

  _requestAnnounce(KNode node) {
    receiveGetPeerResponseNode.sort((KGetPeerInfo a, KGetPeerInfo b) {
      if (a.id == b.id) {
        return 0;
      } else if (a.id.xor(_infoHashId) > b.id.xor(_infoHashId)) {
        return 1;
      } else {
        return -1;
      }
    });
    print("###########announce[${node.nodeDebugId}]  -----${receiveGetPeerResponseNode.length} ${node.rawAnnouncedPeerForSearchResult.length}");
    while (8 < receiveGetPeerResponseNode.length) {
      receiveGetPeerResponseNode.removeAt(8);
    }
    for (KGetPeerInfo i in receiveGetPeerResponseNode) {
      print("###########announce[${node.nodeDebugId}] -----${i.ipAsString}, ${i.port} >>${i.id.xor(_infoHashId).getRootingTabkeIndex()} ::: ${i.id.idAsString}");
      node.sendAnnouncePeerQuery(i.ipAsString, i.port, 1, _infoHashId.id, i.token);
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
          //print("## response query");

            KrpcGetPeersResponse getPeer = response;
            KGetPeerInfo i = new KGetPeerInfo(info.remoteAddress, info.remotePort, getPeer.queriedNodesId, _infoHashId, getPeer.tokenAsKId);
            List<KGetPeerInfo> alreadyHave = KGetPeerInfo.extract(receiveGetPeerResponseNode, (KGetPeerInfo a){
                return a.id == i.id;
            });
            if(alreadyHave.length > 0) {
              receiveGetPeerResponseNode.remove(alreadyHave[0]);
              receiveGetPeerResponseNode.add(i);
            } else {
              receiveGetPeerResponseNode.add(i);
            }

            if (getPeer.haveValue == true) {
             // print("announce set value");
              for (KAnnounceInfo i in getPeer.valuesAsKAnnounceInfo(_infoHashId.id)) {
               // print("----announce set value ${i.port}");
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
