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
  });
}
