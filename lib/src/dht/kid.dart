library hetimatorrent.dht.krpcid;

import 'dart:core';
import 'dart:math';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data';

class KId {
  List<int> _values = null;
  List<int> get id => new List.from(_values);
  String get idAsString => PercentEncode.encode(_values);

  KId(List<int> id) {
    if (id == null || id.length != 20) {
      throw {};
    }
    this._values = new Uint8List.fromList(id);
  }

  KId.zeroClear() {
    this._values = new Uint8List.fromList(new List.filled(20, 0));
  }

  int getRootingTabkeIndex() {
    int ret = 0;
    for (int i = 0, ret = 19; i < 20; i++, ret--) {
      if (_values[i] != 0) {
        for (int j = 0; j < 9; j++) {
          if (_values[i] < (0x1 << j)) {
            return (ret * 8) + j;
          }
        }
        return i;
      }
    }
    return 0;
  }

  static KId _optionTest = new KId(new List.filled(20, 0x7f));
  static List<int> createToken(KId infoHash, KId targetId, KId myId, [KId option = null]) {
    if (option == null) {
      option = _optionTest;
    }
    return infoHash.xor(targetId).xor(myId).xor(option)._values;
  }

  KId xor(KId b, [KId output = null]) {
    if (output == null) {
      output = new KId.zeroClear();
    }
    for (int i = 0; i < b._values.length; i++) {
      output._values[i] = this._values[i] ^ b._values[i];
    }
    return output;
  }

  bool operator >(KId b) {
    for (int i = 0; i < b._values.length; i++) {
      if (this._values[i] == b._values[i]) {
        continue;
      } else if (this._values[i] > b._values[i]) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  bool operator ==(KId b) {
    for (int i = 0; i < b._values.length; i++) {
      if (this._values[i] != b._values[i]) {
        return false;
      }
    }
    return true;
  }

  bool operator >=(KId b) {
    return (this == b ? true : (this > b ? true : false));
  }

  bool operator <(KId b) {
    return (this == b ? false : !(this > b));
  }

  bool operator <=(KId b) {
    return (this == b ? true : (this > b ? false : true));
  }

  int get hashCode {
    int v = 0;
    v = ByteOrder.parseLong(_values, 0, ByteOrder.BYTEORDER_BIG_ENDIAN);
    v ^= ByteOrder.parseLong(_values, 8, ByteOrder.BYTEORDER_BIG_ENDIAN);
    v ^= ByteOrder.parseShort(_values, 16, ByteOrder.BYTEORDER_BIG_ENDIAN);
    return v;
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    for (int i in _values) {
      String a = i.toRadixString(16);
      if (a.length == 1) {
        buffer.write("0");
      }
      buffer.write("${a}.");
    }
    return buffer.toString();
  }

  Iterator<int> get iterator => _values.iterator;

  static int _i = 1000;
  static KId createIDAtRandom([List<int> op = null]) {
    List<int> ret = [];

    Random r = new Random(new DateTime.now().millisecondsSinceEpoch + (_i++));
    for (int i = 0; i < 20; i++) {
      int v = 0xff;
      if (op != null && i < op.length) {
        v = op[i];
      }
      ret.add(r.nextInt(0xff) & v);
    }
    return new KId(ret);
  }
}
