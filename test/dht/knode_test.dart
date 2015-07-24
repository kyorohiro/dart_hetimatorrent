library knode.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;
import 'dart:async';

void main() {
  unit.group('A group of tests', () {
    unit.test("retrive list 0", () {
      Completer c = new Completer();
      List<KNode> knodes = [];
      List<KPeerInfo> kpeerInfos = [];
      int numOfNode = 100;
      for (int i = 0; i < numOfNode; i++) {
        KNode a = new KNode(new HetiSocketBuilderSimu());
        knodes.add(a);
        kpeerInfos.add(new KPeerInfo("127.0.0.1", i, a.nodeId));
        if (i != 0) {
          knodes[i].addKPeerInfo(kpeerInfos[i - 1]);
        }
        knodes[i].addKPeerInfo(kpeerInfos[i]);
      }

      for (int i = 0; i < numOfNode; i++) {
        knodes[i].start(ip: kpeerInfos[i].ipAsString, port: kpeerInfos[i].port);
      }

      return new Future.delayed(new Duration(seconds: 3)).then((_) {
        for (int i = 0; i < numOfNode; i++) {
          int jj = i;
          knodes[i].rootingtable.toInfo().then((String s) {
            print("[${jj}] : ${s}");
          });
        }
      });
    });
  });
}
