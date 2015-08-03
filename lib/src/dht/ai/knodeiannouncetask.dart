library hetimatorrent.dht.knodeai.announcetask;

import 'dart:core';
import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import '../message/krpcgetpeers.dart';
import '../kid.dart';
import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../kpeerinfo.dart';
import '../knode.dart';
import 'kgetpeerinfo.dart';

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
    print("[${node.nodeDebugId}]");
    _isStart = true;
    lastUpdateTime = 0;
    _startSearch(node);
  }

  stopSearchPeer(KNode node, KId infoHash) {
    _isStart = false;
  }

  _startSearch(KNode node) {
    _findedNode.clearAll();
    _updateSearch(node);
  }

  _updateSearch(KNode node) {
    node.rootingtable.findNode(_infoHashId).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      for (KPeerInfo info in infos) {
        if (_findedNode.rawsequential.contains(info)) {
          //node.sendFindNodeQuery(info.ipAsString, info.port, _infoHashId.id).catchError((e) {});
        } else {
          _findedNode.addLast(info);
          node.sendGetPeersQuery(info.ipAsString, info.port, _infoHashId.id).catchError((e) {});
        }
      }
    });
  }

  onTicket(KNode node) {
    if (lastUpdateTime == 0) {
      return;
    }

    int t = new DateTime.now().millisecondsSinceEpoch;
    if (t - lastUpdateTime > 3000) {
      requestAnnounce(node);
      _updateSearch(node);
    }
  }

  requestAnnounce(KNode node) {
    receiveGetPeerResponseNode.sort((KGetPeerInfo a, KGetPeerInfo b) {
      if (a.id == b.id) {
        return 0;
      } else if (a.id.xor(_infoHashId) > b.id.xor(_infoHashId)) {
        return 1;
      } else {
        return -1;
      }
    });
    if (node.verbose) {
      print("###########announce[${node.nodeDebugId}]  -----${receiveGetPeerResponseNode.length} ${node.rawSearchResult.length}");
      for (KGetPeerInfo i in receiveGetPeerResponseNode) {
        print("###########announce[${node.nodeDebugId}] -----${i.ipAsString}, ${i.port} >>${i.id.xor(_infoHashId).getRootingTabkeIndex()} ::: ${i.id.idAsString}");
      }
    }
    // while (8 < receiveGetPeerResponseNode.length) {
    //    receiveGetPeerResponseNode.removeAt(8);
    //  }
    for (KGetPeerInfo i in receiveGetPeerResponseNode) {
      node.sendAnnouncePeerQuery(i.ipAsString, i.port, 1, _infoHashId.id, i.token);
    }
  }

  updateReceveGetPeerInfo(HetiReceiveUdpInfo info, KrpcGetPeersResponse getPeer) {
    KGetPeerInfo i = new KGetPeerInfo(info.remoteAddress, info.remotePort, getPeer.queriedNodesId, _infoHashId, getPeer.tokenAsKId);
    List<KGetPeerInfo> alreadyHave = KGetPeerInfo.extract(receiveGetPeerResponseNode, (KGetPeerInfo a) {
      return a.id == i.id;
    });
    if (alreadyHave.length > 0) {
      receiveGetPeerResponseNode.remove(alreadyHave[0]);
      receiveGetPeerResponseNode.add(i);
    } else {
      receiveGetPeerResponseNode.add(i);
    }
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    if (_isStart == false) {
      return null;
    }
    new Future(() {
      _updateSearch(node);
    });
  }

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response) {
    new Future(() {
      if (_isStart == false) {
        return null;
      }

      if (response.messageSignature == KrpcMessage.GET_PEERS_RESPONSE) {
        KrpcGetPeersResponse getPeer = response;
        updateReceveGetPeerInfo(info, getPeer);

        if (getPeer.haveValue == true) {
          //print("announce set value");
          for (KAnnounceInfo i in getPeer.valuesAsKAnnounceInfo(_infoHashId.id)) {
            lastUpdateTime = new DateTime.now().millisecondsSinceEpoch;
            node.rawSearchResult.addLast(i);
          }
          // todo
          node.sendFindNodeQuery(info.remoteAddress, info.remotePort, _infoHashId.id).catchError((e) {});
        } else {
          //
          //
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
        }
      }
    });
  }
}
