library hetimatorrent.dht.krpcmessage;

import 'dart:core';
import 'dart:async';
import 'dart:math';

class KrpcMessage {}

class Node {
  
}

class NodeId {
  List<int> _id = [];
  List<int> get id => new List.from(_id);

  NodeId(List<int> id) {
    this._id.addAll(id);
  }

  static Future<NodeId> createIDAtRandom([List<int> op = null]) {
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
      return new NodeId(ret);
    });
  }
}
