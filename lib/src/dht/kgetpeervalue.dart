library hetimatorrent.dht.getpeervalue;

import 'dart:core';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimacore/hetimacore.dart';
import 'kid.dart';
import 'dart:typed_data';

class KGetPeerValue {
  int _port = 0;
  int get port => _port;

  List<int> _ip = [];
  List<int> get ip => new List.from(_ip);
  String get ipAsString => HetiIP.toIPString(_ip);
  KId _infoHash = null;
  KId get infoHash => _infoHash;
  String get infoHashAsString => PercentEncode.encode(_infoHash.value);


  KGetPeerValue.fromCompactIpPort(List<int> compact, List<int> infoHash) {
    _init(compact.sublist(0, compact.length - 2), ByteOrder.parseShort(compact, compact.length - 2, ByteOrder.BYTEORDER_BIG_ENDIAN), infoHash);
  }

  KGetPeerValue.fromString(String ip, int port, List<int> infoHash) {
    _init(HetiIP.toRawIP(ip), port, infoHash);
  }

  KGetPeerValue(List<int> ip, int port, List<int> infoHash) {
    _init(ip, port, infoHash);
  }

  _init(List<int> ip, int port, List<int> infoHash) {
    this._ip.addAll(ip);
    this._port = port;
    this._infoHash = new KId(infoHash);
  }

  int get hashCode {
    int ret = 0;
    for (int i in _ip) {
      ret ^= i;
    }
    for (int i in _infoHash) {
      ret ^= i;
    }
    return ret;
  }

  bool operator ==(Object o) {
    if (!(o is KGetPeerValue)) {
      return false;
    }

    KGetPeerValue p = o;
    if (this._ip.length == p._ip.length) {
      for (int i = 0; i < p._ip.length; i++) {
        if (this._ip[i] != p._ip[i]) {
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
    return true;
  }

  static List<Uint8List> toPeerInfoStrings(List<KGetPeerValue> infos) {
    List<Uint8List> ret = [];
    for (KGetPeerValue info in infos) {
      ret.add(new Uint8List.fromList(info.toPeerInfoString()));
    }
    return ret;
  }

  List<int> toPeerInfoString() {
    List<int> ret = [];
    ret.addAll(_ip);
    ret.addAll(ByteOrder.parseShortByte(_port, ByteOrder.BYTEORDER_BIG_ENDIAN));
    return ret;
  }
}

