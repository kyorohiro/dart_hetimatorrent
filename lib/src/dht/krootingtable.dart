library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import '../util/shufflelinkedlist.dart';
import 'package:hetimanet/hetimanet.dart';
import 'kpeerinfo.dart';

class KBucket {
  int k = 20;

  ShuffleLinkedList<KPeerInfo> peerInfos = null;
  KBucket(int k_bucketSize) {
    this.k = k;
    this.peerInfos = new ShuffleLinkedList(k_bucketSize);
  }

  Future update(KPeerInfo peerInfo) {
    return new Future(() {
      peerInfos.addLast(peerInfo);
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

class RootingTable {
  List<KBucket> kBuckets = [];
  Future update(KPeerInfo info) {}

  Future<List<KPeerInfo>> get(List<int> hash) {}
}
