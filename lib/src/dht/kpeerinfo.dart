library hetimatorrent.dht.kpeerinfo;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import '../util/shufflelinkedlist.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimacore/hetimacore.dart';
import 'kid.dart';
import 'dart:typed_data';

class KPeerInfo {
  int _port = 0;
  int get port => _port;

  List<int> _ip = [];
  List<int> get ipAsList => new List.from(_ip);
  String get ipAsString => HetiIP.toIPString(_ip);
  KId _id = null;
  KId get id => _id;

  KPeerInfo(String ip, int port, KId id) {
    _ip.addAll(HetiIP.toRawIP(ip));
    _port = port;
    _id = id;
  }

  KPeerInfo.fromBytes(List<int> buffer, int index, int length) {
    _id = new KId(buffer.sublist(0+index,20+index));
    _ip = buffer.sublist(20+index,24+index);
    _port = ByteOrder.parseShort(buffer, 24+index, ByteOrder.BYTEORDER_BIG_ENDIAN);
  }

  bool operator ==(Object o) {
    if (!(o is KPeerInfo)) {
      return false;
    }
    KPeerInfo p = o;
    if (this._id != p._id) {
      return false;
    }
    if (this._ip.length == p._ip.length) {
      for (int i = 0; i < p._ip.length; i++) {
        if (this._ip[i] != p._ip[i]) {
          return false;
        }
      }
    }
    if (this._port != (o as KPeerInfo)._port) {
      return false;
    }
    return true;
  }

  List<int> toCompactNodeInfo() {
    List<int> ret = [];
    ret.addAll(_id.id);
    ret.addAll(_ip);
    ret.addAll(ByteOrder.parseShortByte(port, ByteOrder.BYTEORDER_BIG_ENDIAN));
    return new Uint8List.fromList(ret);
  }
  
  static List<int> toCompactNodeInfos(List<KPeerInfo> infos) {
    List<int> ret = [];
    for(KPeerInfo info in infos) {
      ret.addAll(info.toCompactNodeInfo());
    }
    return new Uint8List.fromList(ret);
  }
}
