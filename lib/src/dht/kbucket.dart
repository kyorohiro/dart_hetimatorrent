library hetimatorrent.dht.kbucket;

import 'dart:core';
import 'dart:async';
import '../util/shufflelinkedlist.dart';
import 'kpeerinfo.dart';

class KBucket {
  int _k = 20;
  int get k => _k;

  ShuffleLinkedList<KPeerInfo> peerInfos = null;
  KBucket(int k_bucketSize) {
    this._k = _k;
    this.peerInfos = new ShuffleLinkedList(k_bucketSize);
  }

  update(KPeerInfo peerInfo) {
    peerInfos.addLast(peerInfo);
    peerInfos.rawshuffled.sort((KPeerInfo a, KPeerInfo b) {
      if (a.id == b.id) {
        return 0;
      } else if (a.id > b.id) {
        return 1;
      } else {
        return -1;
      }
    });
  }

  int length() {
    return peerInfos.length;
  }

  KPeerInfo getPeerInfo(int index) {
    return peerInfos.getSequential(index);
  }
}
