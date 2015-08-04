library kbucket.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('kbucket', () {
    unit.test("update", () {
      KBucket kbucket = new KBucket(4);
      KPeerInfo info = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 1)));
      kbucket.update(info);
      unit.expect(1, kbucket.length());
      unit.expect(info, kbucket.getPeerInfo(0));
    });

    unit.test("update remove auto", () {
      KBucket kbucket = new KBucket(3);
      KPeerInfo info1 = new KPeerInfo("127.0.0.1", 8081, new KId(new List.filled(20, 1)));
      KPeerInfo info2 = new KPeerInfo("127.0.0.2", 8082, new KId(new List.filled(20, 2)));
      KPeerInfo info3 = new KPeerInfo("127.0.0.3", 8083, new KId(new List.filled(20, 3)));
      KPeerInfo info4 = new KPeerInfo("127.0.0.4", 8084, new KId(new List.filled(20, 4)));

      kbucket.update(info1);
      kbucket.update(info2);
      kbucket.update(info3);
      kbucket.update(info4);

      unit.expect(kbucket.length(), 3);
      unit.expect(info2, kbucket.getPeerInfo(0));
      unit.expect(info3, kbucket.getPeerInfo(1));
      unit.expect(info4, kbucket.getPeerInfo(2));
      unit.expect(kbucket.length(), 3);
    });

    unit.test("update same info", () {
      KBucket kbucket = new KBucket(3);
      KPeerInfo info1 = new KPeerInfo("127.0.0.1", 8081, new KId(new List.filled(20, 1)));
      KPeerInfo info2 = new KPeerInfo("127.0.0.2", 8082, new KId(new List.filled(20, 2)));

      kbucket.update(info1);
      kbucket.update(info2);
      kbucket.update(new KPeerInfo("127.0.0.1", 8081, new KId(new List.filled(20, 1))));

      unit.expect(kbucket.length(), 2);
      unit.expect(info2, kbucket.getPeerInfo(0));
      unit.expect(info1, kbucket.getPeerInfo(1));
    });

    unit.test("update kbucket sort", () {
      KBucket kbucket = new KBucket(3);
      KPeerInfo info2 = new KPeerInfo("127.0.0.2", 8082, new KId(new List.filled(20, 2)));
      KPeerInfo info1 = new KPeerInfo("127.0.0.1", 8081, new KId(new List.filled(20, 1)));
      KPeerInfo info3 = new KPeerInfo("127.0.0.3", 8083, new KId(new List.filled(20, 3)));

      kbucket.update(info1);
      kbucket.update(info2);
      kbucket.update(info3);

      unit.expect(kbucket.length(), 3);
      unit.expect("127.0.0.1", kbucket.peerInfos.rawshuffled[0].ipAsString);
      unit.expect("127.0.0.2", kbucket.peerInfos.rawshuffled[1].ipAsString);
      unit.expect("127.0.0.3", kbucket.peerInfos.rawshuffled[2].ipAsString);
    });
  });
}
