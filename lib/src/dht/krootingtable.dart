library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import '../util/shufflelinkedlist.dart';
import 'kpeerinfo.dart';
import 'kid.dart';
import 'dart:typed_data';
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

  String toInfo() {
    StringBuffer buffer = new StringBuffer();
    for (int j = 0; j < _kBuckets.length; j++) {
        int bucketLength = _kBuckets[j].length();
        if(bucketLength == 0) {continue;}
        buffer.write("[${j}] len:${bucketLength}:## ");
        for(int i=0;i<bucketLength;i++){
          buffer.write(_kBuckets[j].getPeerInfo(i).toString());
        }
        buffer.write("\n");
    }
    return buffer.toString();
  }

  Future update(KPeerInfo info) {
    return new Future(() {
      _kBuckets[_amId.xor(info.id).getRootingTabkeIndex()].update(info);
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


