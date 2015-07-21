library krpcid.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("> >= < <=", () {
      KadId idA = new KadId(new List.filled(20, 0));
      KadId idB = new KadId(new List.filled(20, 1));
      unit.expect(true, idB > idA);
      unit.expect(true, idB >= idA);
      unit.expect(false, idB < idA);
      unit.expect(false, idB <= idA);
      //
      unit.expect(false, idB > idB);
      unit.expect(true, idB >= idB);
      unit.expect(false, idB < idB);
      unit.expect(true, idB <= idB);
    });

    unit.test("xor", () {
      KadId idA = new KadId(new List.filled(20, 255));
      KadId idB = new KadId(new List.filled(20, 1));
      KadId idC = new KadId(new List.filled(20, 254));

      unit.expect(true, idC == idB.xor(idA));
    });

    unit.test("rooting table index", () {
      unit.expect(new KadId.createFromRootingTabkeIndex(0).id,
          [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, 
           0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01]);
      unit.expect(new KadId.createFromRootingTabkeIndex(1).id,
          [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, 
           0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02]);
      unit.expect(new KadId.createFromRootingTabkeIndex(2).id,
          new List.filled(20, 0)..[19]= 0x04);
      unit.expect(new KadId.createFromRootingTabkeIndex(3).id,
          new List.filled(20, 0)..[19]= 0x08);
      unit.expect(new KadId.createFromRootingTabkeIndex(4).id,
          new List.filled(20, 0)..[19]= 0x10);
      unit.expect(new KadId.createFromRootingTabkeIndex(5).id,
          new List.filled(20, 0)..[19]= 0x20);
      unit.expect(new KadId.createFromRootingTabkeIndex(6).id,
          new List.filled(20, 0)..[19]= 0x40);
      unit.expect(new KadId.createFromRootingTabkeIndex(7).id,
          [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, 
           0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80]);
      unit.expect(new KadId.createFromRootingTabkeIndex(8).id,
          new List.filled(20, 0)..[18]= 0x01);
      unit.expect(new KadId.createFromRootingTabkeIndex(159).id,
          [0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, 
           0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]);
    });
  });
}
