library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import 'kpeerinfo.dart';
import 'kid.dart';
import 'kbucket.dart';

class KRootingTable {
  List<KBucket> _kBuckets = [];
  int _kBucketSize = 0;
  KId _ownerKId = null;
  KId get ownerKId => _ownerKId;

  KRootingTable(int k_bucketSize, KId ownerKId) {
    this._kBucketSize = k_bucketSize;
    for (int i = 0; i < 161; i++) {
      _kBuckets.add(new KBucket(k_bucketSize));
    }
    this._ownerKId = ownerKId;
  }

  void clear() {
    for (KBucket k in _kBuckets) {
      k.clear();
    }
  }

  int getRootingTabkeIndex(KId v) {
    return v.getRootingTabkeIndex(_ownerKId);
  }

  void update(KPeerInfo info) {
    _kBuckets[getRootingTabkeIndex(info.id)].add(info);
  }

  String toInfo() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("${ownerKId.toString()}\n");
    for (int j = 0; j < _kBuckets.length; j++) {
      int bucketLength = _kBuckets[j].length;
      if (bucketLength == 0) {
        continue;
      }
      buffer.write("[${j}] len:${bucketLength}:## ");
      for (int i = 0; i < bucketLength; i++) {
        buffer.write(_kBuckets[j][i].toString());
        buffer.write("(^_^)");
      }
      buffer.write("\n");
    }
    return buffer.toString();
  }

  Future<List<KPeerInfo>> findNode(KId id) {
    List<KPeerInfo> ids = [];
    for (KBucket b in _kBuckets) {
      for (KPeerInfo i in b.iterable) {
        ids.add(i);
      }
    }
    ids.sort((KPeerInfo a, KPeerInfo b) {
      return a.id.xor(id).compareTo(b.id.xor(id));
    });
    return new Future(() {
      List<KPeerInfo> ret = [];
      for (KPeerInfo p in ids) {
        ret.add(p);
        if (ret.length >= _kBucketSize) {
          return ret;
        }
      }
      return ret;
    });
  }

}
