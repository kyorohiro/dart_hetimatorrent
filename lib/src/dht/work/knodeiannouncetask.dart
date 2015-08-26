library hetimatorrent.dht.knodeai.announcetask;

import 'dart:core';
import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import '../kid.dart';
import '../krootingtable.dart';

import '../message/krpcmessage.dart';
import '../message/krpcmessage_getpeers.dart';
import '../kpeerinfo.dart';
import '../kgetpeervalue.dart';
import '../knode.dart';
import '../kgetpeernodes.dart';



class KNodeAIAnnounceTask {
  bool _isStart = false;

  KRootingTable _currentClosePeerStack = null;
  List<KGetPeerNodes> receiveGetPeerResponseNode = [];
  List<KGetPeerNodes> _announcedPeers = [];
  List<KPeerInfo> _getPeerNode = [];

  KId _infoHashId = null;
  bool get isStart => _isStart;
  int lastUpdateTime = 0;
  int port = 0;

  bool _getPeerOnly = false;
  bool get getPeerOnly => _getPeerOnly;
  KNodeAIAnnounceTask(KId infoHashId, int port) {
    this._infoHashId = infoHashId;
    this.port = port;
    this._currentClosePeerStack = new KRootingTable(4, infoHashId);
  }

  startSearchPeer(KNode node, KId infoHash, {getPeerOnly: false}) {
    node.log("## startSearchPeer:${_getPeerOnly}");
    _getPeerOnly = getPeerOnly;
    _isStart = true;
    lastUpdateTime = 0;
    _startSearch(node);
  }

  stopSearchPeer(KNode node, KId infoHash) {
    node.log("## stopSearchPeer");
    _isStart = false;
  }

  _startSearch(KNode node) {
    node.log("## _startSearch");
    _getPeerNode.clear();
 //   _ggggg.clear();
    _announcedPeers.clear();
    _updateSearch(node);
  }

  _updateSearch(KNode node) {
    node.log("## _updateSearch");

    node.rootingtable.findNode(_infoHashId).then((List<KPeerInfo> infos) {
      if (_isStart == false) {
        return;
      }
      for (KPeerInfo info in infos) {
        if (_getPeerNode.contains(info)) {
          //node.sendFindNodeQuery(info.ipAsString, info.port, _infoHashId.id).catchError((e) {});
        } else {
          _getPeerNode.add(info);
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
    if (lastUpdateTime != 0 && t - lastUpdateTime > 6000 || t - lastUpdateTime >node.intervalSecondForAnnounce/2) {
      lastUpdateTime = 0;
      requestAnnounce(node);
      _updateSearch(node);
    }
  }

  requestAnnounce(KNode node) {
    node.log("## requestAnnounce");
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
        node.log("Announce[${count}] distance=${i.id.getRootingTabkeIndex(_infoHashId)}");
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
        node.log(
              "###########announce[${node.nodeDebugId}] ---${receiveGetPeerResponseNode.length} ${node.rawSearchResult.length}--${i.ipAsString}, ${i.port} >>${i.id.getRootingTabkeIndex(_infoHashId)} ::: ${i.id.idAsString}");
      }
      if (++count > 8) {
        break;
      }
    }
    if (receiveGetPeerResponseNode.length > 12) {
      receiveGetPeerResponseNode.removeRange(10, receiveGetPeerResponseNode.length);
    }
  }

  updateReceveGetPeerInfo(HetimaReceiveUdpInfo info, KrpcGetPeers getPeer) {    
    if (getPeer.tokenAsKId == null || getPeer.tokenAsKId == null) {
      return;
    }
    KGetPeerNodes i = new KGetPeerNodes(info.remoteAddress, info.remotePort, getPeer.nodeIdAsKId, _infoHashId, getPeer.tokenAsKId);
    if (false == receiveGetPeerResponseNode.contains(i)) {
      receiveGetPeerResponseNode.add(i);
    }
  }

  onReceiveQuery(KNode node, HetimaReceiveUdpInfo info, KrpcMessage query) {
    if (_isStart == false) {
      return null;
    }
    new Future(() {
      _updateSearch(node);
    });
  }

  onReceiveResponse(KNode node, HetimaReceiveUdpInfo info, KrpcMessage response) {
    new Future(() {
      if (_isStart == false) {
        return null;
      }

      if (response.queryFromTransactionId == KrpcMessage.QUERY_GET_PEERS) {
     //   print("##===fin ==> ${response.nodeIdAsKId.getRootingTabkeIndex(_infoHashId)}-------------------ZZZZZZZZZZZ");
        KrpcGetPeers getpeers = response.toKrpcGetPeers();
        updateReceveGetPeerInfo(info, getpeers);

        if (getpeers.haveValue == true) {
          //print("announce set value");
          for (KGetPeerValue i in getpeers.valuesAsKAnnounceInfo(_infoHashId.value)) {
            lastUpdateTime = new DateTime.now().millisecondsSinceEpoch;
            if (false == node.containSeardchResult(i)) {
              node.log("########### get peer value ${i.ipAsString} ${i.port}");
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
          for (KPeerInfo info in getpeers.compactNodeInfoAsKPeerInfo) {
            _currentClosePeerStack.update(info);
          }

          _currentClosePeerStack.findNode(_infoHashId).then((List<KPeerInfo> infos ) {
            for(KPeerInfo i in infos) {
              if(_getPeerNode.contains(i) == false) {
                node.log("##===fin ==> ${i.id.getRootingTabkeIndex(_infoHashId)}-- ${_infoHashId}- ${i.id}  ${i.port}-----------------asdfasdfasdfasdfasd");
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
