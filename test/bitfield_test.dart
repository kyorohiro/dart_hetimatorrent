library bitfield.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("test_bitsizeIsZero", () {
      Bitfield bitfiled = new Bitfield(0,clearIsOne:true);
      unit.expect(0, bitfiled.getBinary().length);
      unit.expect(0, bitfiled.lengthPerBit());
      unit.expect(0, bitfiled.lengthPerByte());
      unit.expect(true, bitfiled.isAllOff());
      unit.expect(true, bitfiled.isAllOn());
    });
  });
}
