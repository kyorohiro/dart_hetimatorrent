library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import '../util/shufflelinkedlist.dart';
import 'package:hetimanet/hetimanet.dart';
import 'kpeerinfo.dart';
import 'kadid.dart';

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

// 161 table 0<=t<=160
class RootingTable {
  List<KBucket> _kBuckets = [];

  RootingTable(int k_bucketSize) {
    for(int i=0;i<161;i++) {
      _kBuckets.add(new KBucket(k_bucketSize));
    }
  }

  Future update(KPeerInfo info) {
    
  }
  
  Future<List<KPeerInfo>> findNode(KadId id) {
  }

}

/**
[1] 
We assign 160-bit opaque ID. lookup algorithm that find closer node.
treat nodes as leaves in a binary tree
       let write btree
Every node have btree
k closet nodes.

   000 0  -2 2  010     C(2-4):010-100
   001 1  -1 3  011     C(2-4):010-100
 + 010 2   0 0  000     A(0-1):000-001
   011 3   1 1  001     B(1-2):001-010
   100 4   2 6  110     D(4-8):100-1000
   101 5   3 7  111     D(4-8):100-1000
   110 6   4 4  100     D(4-8):100-1000
   111 7   5 5  101     D(4-8):100-1000

[2.1] XOR metric

KadNode has a 160bit node id

[2.2 Node state]
store {ipaddress port id]
0<=i<160 2**i-2**l+1
1,  2,  4,  8 , 16, 32
*/