library hetimatorrent.dht.kpeerinfo.getpeerinfo;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import '../../util/shufflelinkedlist.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimacore/hetimacore.dart';
import '../kid.dart';
import 'dart:typed_data';


class KGetPeerNodes {
  int _port = 0;
  int get port => _port;

  List<int> _ip = [];
  List<int> get ip => new List.from(_ip);
  String get ipAsString => HetiIP.toIPString(_ip);

  KId _infoHash = null;
  KId get infoHash => _infoHash;
  String get infoHashAsString => PercentEncode.encode(_infoHash.value);

  List<int> _token = [];
  List<int> get token => _token;
  List<int> get rawToken => _token;
  KId _id = null;
  KId get id => _id;

  static String toIPFromCompact(List<int> compact) {
    return HetiIP.toIPString(compact.sublist(0, compact.length - 2));
  }

  static int toPortFromCompact(List<int> compact) {
    return ByteOrder.parseShort(compact, compact.length - 2, ByteOrder.BYTEORDER_BIG_ENDIAN);
  }

  KGetPeerNodes(String ip, int port, KId id, KId infoHash, List<int> token) {
    this._ip.addAll(HetiIP.toRawIP(ip));
    this._port = port;
    this._infoHash = infoHash;
    this._id = id;
    this._token.addAll(token);
  }

  int get hashCode {
    int ret = 0;
    for (int i in _ip) {
      ret ^= i;
    }
    for (int i in _token) {
      ret ^= i;
    }
    ret ^= _infoHash.hashCode;
    ret ^= _id.hashCode;
    ret ^= _port;
    return ret;
  }

  bool operator ==(Object o) {
    if (!(o is KGetPeerNodes)) {
      return false;
    }

    KGetPeerNodes p = o;
    if (this._ip.length == p._ip.length) {
      for (int i = 0; i < p._ip.length; i++) {
        if (this._ip[i] != p._ip[i]) {
          return false;
        }
      }
    }
    if (this._token.length == p._token.length) {
      for (int i = 0; i < p._token.length; i++) {
        if (this._token[i] != p._token[i]) {
          return false;
        }
      }
    }
    if (this._port != p._port) {
      return false;
    }
    
    if (this._infoHash != p._infoHash) {
      return false;
    }
    if (this._id != p._id) {
      return false;
    }
    return true;
  }
  
  static List<KGetPeerNodes> extract(List<KGetPeerNodes> vs, bool filter(KGetPeerNodes a)) {
    List<KGetPeerNodes> ret = [];
    for(KGetPeerNodes v in vs) {
      if(filter(v) == true) { 
        ret.add(v);
      }
    }
    return ret;
  }
  static bool contain(List<KGetPeerNodes> vs, bool filter(KGetPeerNodes a)) {
    for(KGetPeerNodes v in vs) {
      if(filter(v) == true) { 
        return true;
      }
    }
    return false;
  }
}
