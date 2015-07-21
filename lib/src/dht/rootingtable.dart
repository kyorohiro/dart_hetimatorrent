library hetimatorrent.dht.rootingtable;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import '../util/shufflelinkedlist.dart';
import 'package:hetimanet/hetimanet.dart';

class KBucket {
  int k = 20;

  ShuffleLinkedList<KPeerInfo> peerInfos = new ShuffleLinkedList();
  KBucket(int k_bucketSize) {
    this.k = k;
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

class KPeerInfo {
  int _port = 0;
  int get port => _port;

  List<int> _ip = [];
  List<int> get ipAsList => new List.from(_ip);
  String get ipAsString => HetiIP.toIPString(_ip);
  List<int> _id = [];
  List<int> get id => new List.from(_id);

  KPeerInfo(String ip, int port, List<int> id) {
    _ip.addAll(HetiIP.toRawIP(ip));
    _port = port;
    _id.addAll(id);
  }
  
  bool operator== (Object o) {
    if(!(o is KPeerInfo)) {
      return false;
    }
    if(this._id != (o as KPeerInfo)._id) {
      return false;
    }
    if(this._ip != (o as KPeerInfo)._ip) {
      return false;
    }
    if(this._port != (o as KPeerInfo)._port) {
      return false;
    }
    return true;
  }
}

class RootingTable {
  List<KBucket> kBuckets = [];
  Future update(KPeerInfo info) {}

  Future<List<KPeerInfo>> get(List<int> hash) {}
}
