library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import '../util/shufflelinkedlist.dart';
import 'package:hetimanet/hetimanet.dart';
import 'kpeerinfo.dart';

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
  
  List<KBucket> _kBuckets = [];

  RootingTable(int k_bucketSize) {
    _kBuckets.add(new KBucket(k_bucketSize));
  }

  Future update(KPeerInfo info) {
    
  }
  
  Future<List<KPeerInfo>> findNode() {
    ;
  }

  Future<List<KPeerInfo>> get(List<int> hash) {
    ;
  }
}
