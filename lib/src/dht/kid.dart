library hetimatorrent.dht.krpcid;

import 'dart:core';
import 'dart:math';
import 'package:hetimacore/hetimacore.dart';

class KId {
  List<int> _id = [];
  List<int> get id => new List.from(_id);
  String get idAsString => PercentEncode.encode(_id);

  KId(List<int> id) {
    if(id == null || id.length != 20) {
      throw {};
    }
    this._id.addAll(id);
  }

  /// 159 is long distance
  /// 0 is short distance
  KId.createFromRootingTabkeIndex(int tableIndex) {
    List<int> p = new List.filled(20, 0);
    int indexPerByte = tableIndex ~/ 8;
    int inputPerByte = 0x01 << (tableIndex % 8);
    p[19 - indexPerByte] = inputPerByte;
    this._id.addAll(p);
  }

  int getRootingTabkeIndex() {
    int ret = 0;
    for (int i = 0,ret=19; i < 20; i++, ret--) {
      if (_id[i] != 0) {
        for (int j = 0; j < 9; j++) {
          if (_id[i] < (0x1 << j)) {
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
    if(option == null) {
      option = _optionTest;
    }
    return infoHash.xor(targetId).xor(myId).xor(option)._id;
  }

  KId xor(KId b) {
    List<int> ret = [];
    for (int i = 0; i < b._id.length; i++) {
      ret.add(this._id[i] ^ b._id[i]);
    }
    return new KId(ret);
  }

  bool operator >(KId b) {
    for (int i = 0; i < b._id.length; i++) {
      if (this._id[i] == b._id[i]) {
        continue;
      } else if (this._id[i] > b._id[i]) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  bool operator ==(KId b) {
    for (int i = 0; i < b._id.length; i++) {
      if (this._id[i] != b._id[i]) {
        return false;
      }
    }
    return true;
  }

  int get hashCode {
    int v = 0;
    v = ByteOrder.parseLong(_id, 0, ByteOrder.BYTEORDER_BIG_ENDIAN);
    v ^= ByteOrder.parseLong(_id, 8, ByteOrder.BYTEORDER_BIG_ENDIAN);
    v ^= ByteOrder.parseShort(_id, 16, ByteOrder.BYTEORDER_BIG_ENDIAN);
    return v;
  }

  bool operator >=(KId b) {
    if (this == b) {
      return true;
    } else if (this > b) {
      return true;
    } else {
      return false;
    }
  }

  bool operator <(KId b) {
    if (this == b) {
      return false;
    } else {
      return !(this > b);
    }
  }

  bool operator <=(KId b) {
    if (this == b) {
      return true;
    } else if (this > b) {
      return false;
    } else {
      return true;
    }
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    for(int i in _id) {
      String a = i.toRadixString(16);
      if(a.length ==1) {
        buffer.write("0");
      } 
      buffer.write("${a}.");
    }
    return buffer.toString();
  }

  static int _i =1000;
  static KId createIDAtRandom([List<int> op = null]) {
    List<int> ret = [];

    Random r = new Random(new DateTime.now().millisecondsSinceEpoch+(_i++));
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
