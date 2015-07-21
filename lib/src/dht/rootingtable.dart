library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import '../util/shufflelinkedlist.dart';

class KBucket {
  int k = 20;

  ShuffleLinkedList<KPeerInfo> peerInfos = new ShuffleLinkedList();
  KBucket(int k_bucketSize) {
    this.k = k;
  }
}

class KPeerInfo {
  
}
class RootingTable {
  List<KBucket> kBuckets = [];
  Future update(KPeerInfo info) {
    
  }
  
  Future<List<KPeerInfo>> get(List<int> hash) {
    
  }
}

