library hetimatorrent.dht.kbucket;

import 'dart:core';
import 'kpeerinfo.dart';

class KBucket {
  int _k = 8;
  int get k => _k;
  List<KPeerInfo> peerInfos = null;

  KBucket(int kBucketSize) {
    this._k = kBucketSize;
    this.peerInfos = [];
  }

  add(KPeerInfo peerInfo) {
    if (peerInfos.contains(peerInfo) == true) {
      peerInfos.remove(peerInfo);
    }
    peerInfos.add(peerInfo);
    if (peerInfos.length > k) {
      peerInfos.removeAt(0);
    }
  }

  int get length => peerInfos.length;
  KPeerInfo operator [](int idx) => peerInfos[idx];
  Iterator<KPeerInfo> get iterator => peerInfos.iterator;
  Iterable<KPeerInfo> get iterable => peerInfos;
  clear() {
    peerInfos.clear();
  }
}
