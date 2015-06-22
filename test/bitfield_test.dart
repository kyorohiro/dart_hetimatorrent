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

    unit.test("test_bitsizeIsZero", () {
      Bitfield bitfield = new Bitfield(1);
      unit.expect(bitfield.getBinary().length, 1);
      unit.expect(1, bitfield.lengthPerBit());
      unit.expect(1, bitfield.lengthPerByte());
      unit.expect(false, bitfield.isAllOff());
      unit.expect(true, bitfield.isAllOn());
      unit.expect(0x80, 0xFF&bitfield.getBinary()[0]);
      
      unit.expect(true, bitfield.getIsOn(0));
      bitfield.setIsOn(0, false);
      unit.expect(false, bitfield.getIsOn(0));
      bitfield.oneClear();
      unit.expect(true, bitfield.getIsOn(0));
      unit.expect(0x80, 0xFF&bitfield.getBinary()[0]);

      bitfield.zeroClear();
      unit.expect(false, bitfield.getIsOn(0));
      unit.expect(0x00, 0xFF&bitfield.getBinary()[0]);
    });
  });
}
