library hetimatorrent.dht.rootingtable;

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
class KRootingTable {
  List<KBucket> _kBuckets = [];
  int _kBucketSize = 0;

  KRootingTable(int k_bucketSize) {
    this._kBucketSize = k_bucketSize;
    for (int i = 0; i < 161; i++) {
      _kBuckets.add(new KBucket(k_bucketSize));
    }
  }

  Future<String> toInfo() {
    List<Future> ll = [];
    List<Future> ls = [];
    for (int i = 0; i < _kBuckets.length; i++) {
        ls.add(_kBuckets[i].length().then((int xx) {
         // print("${xx}");
          List<Future> l = [];
          for (int j = 0; j < xx; j++) {
            l.add(_kBuckets[i].getPeerInfo(j).then((KPeerInfo info) {
              return "${info.ipAsString}:${info.port}";
            }));
          }
          if(l.length != 0) {
          ll.add(Future.wait(l).then((List<String> rr) {
            StringBuffer b = new StringBuffer();
            b.write("${i}:");
            for (String r in rr) {
              b.write("${r},");
            }
            b.write("\n");
            return b.toString();
          }));
          }
        }));
    }
    return Future.wait(ls).then((_) {
      return Future.wait(ll).then((List<String> e) {
        StringBuffer b = new StringBuffer();
        for (String r in e) {
          b.write("${r},");
        }
        b.write("\n");
        return b.toString();
      });
    });
  }
  Future update(KPeerInfo info) {
    return new Future(() {
      _kBuckets[info.id.getRootingTabkeIndex()].update(info);
    });
  }

  Future<List<KPeerInfo>> findNode(KId id) {
    return new Future(() {
      int targetIndex = id.getRootingTabkeIndex();
      List<KPeerInfo> ret = [];
      for (int v in retrievePath(targetIndex)) {
        for (KPeerInfo p in _kBuckets[v].peerInfos.sequential) {
          ret.add(p);
          if (ret.length >= _kBucketSize) {
            return ret;
          }
        }
      }
      return ret;
    });
  }

  List<int> retrievePath(int index) {
    List<int> ret = [index];
    int head = index - 1;
    int tail = index + 1;
    while (true) {
      if (head >= 0) {
        ret.add(head);
        head--;
      }
      if (tail <= 160) {
        ret.add(tail);
        tail++;
      }
      if (head < 0 && tail > 160) {
        return ret;
      }
    }
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
