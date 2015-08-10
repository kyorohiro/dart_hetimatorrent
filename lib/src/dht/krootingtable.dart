library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import 'kpeerinfo.dart';
import 'kid.dart';
import 'kbucket.dart';

// 161 table 0<=t<=160
class KRootingTable {
  List<KBucket> _kBuckets = [];
  int _kBucketSize = 0;
  KId _amId = null;
  KId get amId => _amId;


  KRootingTable(int k_bucketSize, KId amId) {
    this._kBucketSize = k_bucketSize;
    for (int i = 0; i < 161; i++) {
      _kBuckets.add(new KBucket(k_bucketSize));
    }
    this._amId = amId;
  }

  static int getRootingTabkeIndex(KId v) {
    for (int i = 0, ret = 19; i < 20; i++, ret--) {
      if (v[i] != 0) {
        for (int j = 0; j < 9; j++) {
          if (v[i] < (0x1 << j)) {
            return (ret * 8) + j;
          }
        }
        return i;
      }
    }
    return 0;
  }

  String toInfo() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("${amId.toString()}\n");
    for (int j = 0; j < _kBuckets.length; j++) {
        int bucketLength = _kBuckets[j].length;
        if(bucketLength == 0) {continue;}
        buffer.write("[${j}] len:${bucketLength}:## ");
        for(int i=0;i<bucketLength;i++){
          buffer.write(_kBuckets[j][i].toString());
          buffer.write("(^_^)");
        }
        buffer.write("\n");
    }
    return buffer.toString();
  }

  Future update(KPeerInfo info) {
    return new Future(() {
      _kBuckets[KRootingTable.getRootingTabkeIndex(_amId.xor(info.id))].add(info);
    });
  }

  Future<List<KPeerInfo>> findNode(KId id) {
    return new Future(() {
      int targetIndex = KRootingTable.getRootingTabkeIndex(id.xor(_amId));
      List<KPeerInfo> ret = [];
      for (int v in retrievePath(targetIndex)) {
        for (KPeerInfo p in _kBuckets[v].peerInfos) {
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


