library hetimatorrent.dht.kpeerinfo;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import '../util/shufflelinkedlist.dart';
import 'package:hetimanet/hetimanet.dart';
import 'kadid.dart';

class KPeerInfo {
  int _port = 0;
  int get port => _port;

  List<int> _ip = [];
  List<int> get ipAsList => new List.from(_ip);
  String get ipAsString => HetiIP.toIPString(_ip);
  KadId _id = null;
  KadId get id => _id;

  KPeerInfo(String ip, int port, KadId id) {
    _ip.addAll(HetiIP.toRawIP(ip));
    _port = port;
    _id = id;
  }
  
  bool operator== (Object o) {
    if(!(o is KPeerInfo)) {
      return false;
    }
    KPeerInfo p = o;
    if(this._id != p._id) {
          return false;
    }
    if(this._ip.length == p._ip.length) {
      for(int i=0;i<p._ip.length;i++) {
        if(this._ip[i] != p._ip[i]){
          return false;
        }
      }
    }
    if(this._port != (o as KPeerInfo)._port) {
      return false;
    }
    return true;
  }
}

