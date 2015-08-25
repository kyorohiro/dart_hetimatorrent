library keootingtable.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("retrive list update", () {
      KRootingTable table = new KRootingTable(8, new KId(new List.filled(20, 3)));
      KPeerInfo info = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 1)));
      table.update(info);
      return table.findNode(new KId(new List.filled(20, 0))).then((List<KPeerInfo> infos) {
        unit.expect(infos.length, 1);
        print("##### ${table.toInfo()}");
      });
    });
    unit.test("retrive list update", () {
      KRootingTable table = new KRootingTable(8, new KId(new List.filled(20, 4)));
      KPeerInfo info = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 1)));
      table.update(info);
      return table.findNode(new KId(new List.filled(20, 0))).then((List<KPeerInfo> infos) {
        unit.expect(infos.length, 1);
        print("##### ${table.toInfo()}");
      });
    });
  });
}
