library hetimatorrent.dht.kbucket;

import 'dart:core';
import 'dart:async';
import '../util/shufflelinkedlist.dart';
import 'kpeerinfo.dart';
import 'kid.dart';
import 'dart:typed_data';

class KBucket {
  int _k = 20;
  int get k => _k;

  ShuffleLinkedList<KPeerInfo> peerInfos = null;
  KBucket(int k_bucketSize) {
    this._k = _k;
    this.peerInfos = new ShuffleLinkedList(k_bucketSize);
  }

  Future update(KPeerInfo peerInfo) {
    return new Future(() {
      peerInfos.addLast(peerInfo);
      peerInfos.rawshuffled.sort((KPeerInfo a, KPeerInfo b) {
        if(a.id == b.id) {
          return 0;
        } 
        else if(a.id > b.id) {
          return 1;
        } else {
          return -1;
        }
      });
    });
  }

  Future<int> length() {
    return new Future(() {
      return peerInfos.length;
    });
  }

  Future<KPeerInfo> getPeerInfo(int index) {
    return new Future(() {
      return peerInfos.getSequential(index);
    });
  }
}
