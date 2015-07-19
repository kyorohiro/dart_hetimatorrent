library hetimatorrent.dht.krpcid;

import 'dart:core';
import 'dart:async';
import 'dart:math';

class KrpcId {
  List<int> _id = [];
  List<int> get id => new List.from(_id);

  KrpcId(List<int> id) {
    this._id.addAll(id);
  }

  KrpcId xor(KrpcId b) {
    List<int> ret = [];
    for (int i = 0; i < b._id.length; i++) {
      ret.add(this._id[i] ^ b._id[i]);
    }
    return new KrpcId(ret);
  }

  bool operator >(KrpcId b) {
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

  bool operator ==(KrpcId b) {
    for (int i = 0; i < b._id.length; i++) {
      if (this._id[i] != b._id[i]) {
        return false;
      }
    }
    return true;
  }

  bool operator >=(KrpcId b) {
    if (this == b) {
      return true;
    } else if (this > b) {
      return true;
    } else {
      return false;
    }
  }

  bool operator <(KrpcId b) {
    if (this == b) {
      return false;
    } else {
      return !(this > b);
    }
  }

  bool operator <=(KrpcId b) {
    if (this == b) {
      return true;
    } else if (this > b) {
      return false;
    } else {
      return true;
    }
  }
}

