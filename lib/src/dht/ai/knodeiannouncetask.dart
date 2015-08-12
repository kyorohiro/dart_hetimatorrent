library hetimatorrent.dht.knodeai.announcetask;

import 'dart:core';
import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import '../kid.dart';
import '../krootingtable.dart';

import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../kpeerinfo.dart';
import '../message/kgetpeervalue.dart';
import '../knode.dart';
import '../message/kgetpeernodes.dart';

class KPeetInfoPlus extends KPeerInfo {
  bool requestIsDone = false;
  KPeetInfoPlus(KPeerInfo base) : super(base.ipAsString, base.port, base.id) {}
  static sort(List<KPeerInfo> findedPeers, KId _infoHashId) {
    findedPeers.sort((KPeetInfoPlus a, KPeetInfoPlus b) {
      if (a.id == b.id) {
        return 0;
      } else if (a.id.xor(_infoHashId) > b.id.xor(_infoHashId)) {
        return 1;
      } else {
        return -1;
      }
    });
  }
}

class KNodeAIAnnounceTask {
  bool _isStart = false;
  //ShuffleLinkedList<KPeerInfo> _findedNode = new ShuffleLinkedList(50);

  KRootingTable _ggggg = null;
  List<KGetPeerNodes> receiveGetPeerResponseNode = [];
  List<KGetPeerNodes> _announcedPeers = [];
  List<KPeetInfoPlus> _getPeerNode = [];

  KId _infoHashId = null;
  bool get isStart => _isStart;
  int lastUpdateTime = 0;
  int port = 0;

  bool _getPeerOnly = false;
  bool get getPeerOnly => _getPeerOnly;
  KNodeAIAnnounceTask(KId infoHashId, int port) {
    this._infoHashId = infoHashId;
    this.port = port;
    this._ggggg = new KRootingTable(4, infoHashId);
  }

  startSearchPeer(KNode node, KId infoHash, {getPeerOnly: false}) {
    if (node.verbose == true) {
      print("## startSearchPeer:${_getPeerOnly}");
    }
    _getPeerOnly = getPeerOnly;
    _isStart = true;
    lastUpdateTime = 0;
    _startSearch(node);
  }

  stopSearchPeer(KNode node, KId infoHash) {
    if (node.verbose == true) {
      print("## stopSearchPeer");
    }
    _isStart = false;
  }

  _startSearch(KNode node) {
    if (node.verbose == true) {
      print("## _startSearch");
    }
    _getPeerNode.clear();
    _announcedPeers.clear();
    _updateSearch(node);
  }

  _updateSearch(KNode node) {
    if (node.verbose == true) {
      print("## _updateSearch");
    }

    node.rootingtable.findNode(_infoHashId).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      for (KPeerInfo info in infos) {
        if (_getPeerNode.contains(info)) {
          //node.sendFindNodeQuery(info.ipAsString, info.port, _infoHashId.id).catchError((e) {});
        } else {
          _getPeerNode.add(new KPeetInfoPlus(info));
          node.sendGetPeersQuery(info.ipAsString, info.port, _infoHashId.value).catchError((e) {});
        }
      }
    });
  }

  onTicket(KNode node) {
    if (lastUpdateTime == 0) {
      return;
    }

    int t = new DateTime.now().millisecondsSinceEpoch;
    if (lastUpdateTime != 0 && t - lastUpdateTime > 3000) {
      lastUpdateTime = 0;
      requestAnnounce(node);
      _updateSearch(node);
    }
  }

  requestAnnounce(KNode node) {
    if (node.verbose == true) {
      print("## requestAnnounce");
    }
    if (_getPeerOnly == true) {
      return;
    }
    receiveGetPeerResponseNode.sort((KGetPeerNodes a, KGetPeerNodes b) {
      if (a.id == b.id) {
        return 0;
      } else if (a.id.xor(_infoHashId) > b.id.xor(_infoHashId)) {
        return 1;
      } else {
        return -1;
      }
    });

    {
      int count = 0;
      for (KGetPeerNodes i in receiveGetPeerResponseNode) {
        print("Announce[${count}] distance=${i.id.getRootingTabkeIndex(_infoHashId)}");
        if (++count > 20) {
          break;
        }
      }
    }
    int count = 0;
    for (KGetPeerNodes i in receiveGetPeerResponseNode) {
      if (false == _announcedPeers.contains(i)) {
        node.sendAnnouncePeerQuery(i.ipAsString, i.port, 0, _infoHashId.value, this.port, i.token).catchError((_) {});
        _announcedPeers.add(i);
        if (node.verbose) {
          print(
              "###########announce[${node.nodeDebugId}] ---${receiveGetPeerResponseNode.length} ${node.rawSearchResult.length}--${i.ipAsString}, ${i.port} >>${i.id.getRootingTabkeIndex(_infoHashId)} ::: ${i.id.idAsString}");
        }
      }
      if (++count > 8) {
        break;
      }
    }
    if (receiveGetPeerResponseNode.length > 12) {
      receiveGetPeerResponseNode.removeRange(10, receiveGetPeerResponseNode.length);
    }
  }

  updateReceveGetPeerInfo(HetiReceiveUdpInfo info, KrpcMessage getPeer) {
    if (getPeer.tokenAsKId == null || getPeer.tokenAsKId == null) {
      return;
    }
    KGetPeerNodes i = new KGetPeerNodes(info.remoteAddress, info.remotePort, getPeer.nodeIdAsKId, _infoHashId, getPeer.tokenAsKId);
    List<KGetPeerNodes> alreadyHave = KGetPeerNodes.extract(receiveGetPeerResponseNode, (KGetPeerNodes a) {
      return a.id == i.id;
    });
    if (alreadyHave.length > 0) {
      receiveGetPeerResponseNode.remove(alreadyHave[0]);
      receiveGetPeerResponseNode.add(i);
    } else {
      receiveGetPeerResponseNode.add(i);
    }
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcMessage query) {
    if (_isStart == false) {
      return null;
    }
    new Future(() {
      _updateSearch(node);
    });
  }

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcMessage response) {
    new Future(() {
      if (_isStart == false) {
        return null;
      }

      if (response.messageSignature == KrpcMessage.GET_PEERS_RESPONSE) {
        updateReceveGetPeerInfo(info, response);

        if (response.haveValue == true) {
          //print("announce set value");
          for (KGetPeerValue i in response.valuesAsKAnnounceInfo(_infoHashId.value)) {
            lastUpdateTime = new DateTime.now().millisecondsSinceEpoch;
            if (node.verbose == true && false == node.containSeardchResult(i)) {
              print("########### get peer value ${i.ipAsString} ${i.port}");
            }
            node.addSeardchResult(i);
          }
          //
          // todo
          node.sendFindNodeQuery(info.remoteAddress, info.remotePort, _infoHashId.value).catchError((e) {});
        } else {
          //
          //
          List<KPeerInfo> candidate = [];
          for (KPeerInfo info in response.compactNodeInfoAsKPeerInfo) {
            _ggggg.update(info);
          }

          _ggggg.findNode(_infoHashId).then((List<KPeerInfo> infos ) {
            for(KPeerInfo i in infos) {
              if(_getPeerNode.contains(i) == false) {
                print("##===fin ==> ${i.id.getRootingTabkeIndex(_infoHashId)}-------------------asdfasdfasdfasdfasd");
                _getPeerNode.add(i);
                lastUpdateTime = new DateTime.now().millisecondsSinceEpoch;
                node.sendGetPeersQuery(i.ipAsString, i.port, _infoHashId.value).catchError((_) {});
              }
            }
          });
        }
      }
    });
  }
}
