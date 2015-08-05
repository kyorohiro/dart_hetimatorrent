library knode002.test;

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
      List<KNode> knodes = [];
      List<KPeerInfo> kpeerInfos = [];
      int numOfNode = 20;
      for (int i = 0; i < numOfNode; i++) {
        KNode a = new KNode(new HetiSocketBuilderSimu(),intervalSecondForMaintenance:1,intervalSecondForAnnounce:5, verbose:(i==2));
        knodes.add(a);
        kpeerInfos.add(new KPeerInfo("127.0.0.1", i, a.nodeId));
        if (i != 0) {
          knodes[i].addKPeerInfo(kpeerInfos[i - 1]);
        }
      }

      for (int i = 0; i < numOfNode; i++) {
        knodes[i].addKPeerInfo(kpeerInfos[(i + numOfNode ~/ 2) % numOfNode]);
      }

      for (int i = 0; i < numOfNode; i++) {
        knodes[i].start(ip: kpeerInfos[i].ipAsString, port: kpeerInfos[i].port);
      }

      KId valueInfoHash = KId.createIDAtRandom();
      return new Future.delayed(new Duration(seconds: 3)).then((_) {
        knodes[2].startSearchValue(valueInfoHash,39999);
        knodes[2].onGetPeerValue.listen((KGetPeerValue v) {
          print("---onGetPeerValue ${v.ipAsString} ${v.port} ${v.infoHashAsString} ----------------------------------------");
        });
        return new Future.delayed(new Duration(seconds: 5));
      }).then((_) {
        knodes[numOfNode ~/ 2].startSearchValue(valueInfoHash,38888);
        for (int d = 0; d < numOfNode; d += 5) {
          knodes[d].updateP2PNetwork();
        }
        return new Future.delayed(new Duration(seconds: 10)).then((_) {
          print("#[1]# end");
          print("#[1]# test ${knodes[2].rawSearchResult.length}");
          print("#[1]# test ${knodes[numOfNode~/3].rawSearchResult.length}");
          return new Future.delayed(new Duration(seconds: 1));
        }).then((_) {
          print("#[2]# end");
          print("#[1]# test ${knodes[2].rawSearchResult.length}");
          print("#[2]# test ${knodes[numOfNode~/3].rawSearchResult.length}");
        }).catchError((e) {
          print("# erro ${e}");
        });
      });
    });
  });
}
