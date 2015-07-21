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
      KPeerInfo info = new KPeerInfo("127.0.0.1", 8080, new List.filled(20, 1));
      kbucket.update(info);
      return kbucket.length().then((int length) {
        unit.expect(length, 1);
        return kbucket.getPeerInfo(0).then((KPeerInfo i) {
          unit.expect(info, i);
        });
      });
    });
    
    unit.test("update remove auto", () {
      KBucket kbucket = new KBucket(3);
      KPeerInfo info1 = new KPeerInfo("127.0.0.1", 8081, new List.filled(20, 1));
      KPeerInfo info2 = new KPeerInfo("127.0.0.2", 8082, new List.filled(20, 2));
      KPeerInfo info3 = new KPeerInfo("127.0.0.3", 8083, new List.filled(20, 3));
      KPeerInfo info4 = new KPeerInfo("127.0.0.4", 8084, new List.filled(20, 4));

      kbucket.update(info1);
      kbucket.update(info2);
      kbucket.update(info3);
      kbucket.update(info4);

      return kbucket.length().then((int length) {
        unit.expect(length, 3);
        return kbucket.getPeerInfo(0).then((KPeerInfo i) {
          unit.expect(info2, i);
          return kbucket.getPeerInfo(1);
        }).then((KPeerInfo i) {
          unit.expect(info3, i);
          return kbucket.getPeerInfo(2);
        }).then((KPeerInfo i) {
          unit.expect(info4, i);
        });
      });
    });
    
    unit.test("update same info", () {
      KBucket kbucket = new KBucket(3);
      KPeerInfo info1 = new KPeerInfo("127.0.0.1", 8081, new List.filled(20, 1));
      KPeerInfo info2 = new KPeerInfo("127.0.0.2", 8082, new List.filled(20, 2));

      kbucket.update(info1);
      kbucket.update(info2);
      kbucket.update(new KPeerInfo("127.0.0.1", 8081, new List.filled(20, 1)));

      return kbucket.length().then((int length) {
        unit.expect(length, 2);
        return kbucket.getPeerInfo(0).then((KPeerInfo i) {
          unit.expect(info2, i);
          return kbucket.getPeerInfo(1);
        }).then((KPeerInfo i) {
          unit.expect(info1, i);
        });
      });
    });
  });
}
