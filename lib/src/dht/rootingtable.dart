library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import 'dart:math';


class KBucket {
  int k = 20;
  List<KPeerInfo> peerInfos = [];

  KBucket(int k_bucketSize) {
    this.k = k;
  }
}

class KPeerInfo {
  
}
class RootingTable {
  List<KBucket> kBuckets = [];
}

