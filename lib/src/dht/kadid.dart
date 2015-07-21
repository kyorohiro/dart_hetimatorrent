library hetimatorrent.dht.krpcid;

import 'dart:core';
import 'dart:async';
import 'dart:math';

class KadId {
  List<int> _id = [];
  List<int> get id => new List.from(_id);

  KadId(List<int> id) {
    this._id.addAll(id);
  }

  KadId.create0_2xx160(int id) {
    List<int> p = new List.filled(20, 0);
    int index = id ~/ 8;
    int input = 0x01 << (id % 8);
    p[index] = input;
    this._id.addAll(p);
  }

  KadId xor(KadId b) {
    List<int> ret = [];
    for (int i = 0; i < b._id.length; i++) {
      ret.add(this._id[i] ^ b._id[i]);
    }
    return new KadId(ret);
  }

  bool operator >(KadId b) {
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

  bool operator ==(KadId b) {
    for (int i = 0; i < b._id.length; i++) {
      if (this._id[i] != b._id[i]) {
        return false;
      }
    }
    return true;
  }

  bool operator >=(KadId b) {
    if (this == b) {
      return true;
    } else if (this > b) {
      return true;
    } else {
      return false;
    }
  }

  bool operator <(KadId b) {
    if (this == b) {
      return false;
    } else {
      return !(this > b);
    }
  }

  bool operator <=(KadId b) {
    if (this == b) {
      return true;
    } else if (this > b) {
      return false;
    } else {
      return true;
    }
  }

  static Future<KadId> createIDAtRandom([List<int> op = null]) {
    return new Future(() {
      List<int> ret = [];

      Random r = new Random(new DateTime.now().millisecondsSinceEpoch);
      for (int i = 0; i < 20; i++) {
        int v = 0xff;
        if (op != null && i < op.length) {
          v = op[i];
        }
        ret.add(r.nextInt(0xff) & v);
      }
      return new KadId(ret);
    });
  }
}
