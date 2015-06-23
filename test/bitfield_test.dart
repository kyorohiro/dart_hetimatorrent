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

    unit.test("test_bitsizeIsNine", () {
      Bitfield bitfield = new Bitfield(9);
      unit.expect(2, bitfield.getBinary().length);
      unit.expect(9, bitfield.lengthPerBit());
      unit.expect(2, bitfield.lengthPerByte());
      unit.expect(false, bitfield.isAllOff());
      unit.expect(true, bitfield.isAllOn());
      unit.expect(0xFF, 0xFF&bitfield.getBinary()[0]);
      unit.expect(0x80, 0xFF&bitfield.getBinary()[1]);

      for(int i=0;i<bitfield.lengthPerBit();i++){
        unit.expect(true, bitfield.getIsOn(i));
      }

      bitfield.setIsOn(1, false);
      unit.expect(false, bitfield.getIsOn(1));

      bitfield.setIsOn(8, false);
      unit.expect(false, bitfield.getIsOn(8));

      unit.expect(false, bitfield.isAllOff());
      unit.expect(false, bitfield.isAllOn());

      bitfield.oneClear();
      unit.expect(false, bitfield.isAllOff());
      unit.expect(true, bitfield.isAllOn());
      
      bitfield.zeroClear();
      unit.expect(true, bitfield.isAllOff());
      unit.expect(false, bitfield.isAllOn());
    });
    
    unit.test("test_bitsizeIs72", () {
      Bitfield bitfield = new Bitfield(70);
      unit.expect(9, bitfield.getBinary().length);
      unit.expect(70, bitfield.lengthPerBit());
      unit.expect(9, bitfield.lengthPerByte());
      unit.expect(false, bitfield.isAllOff());
      unit.expect(true, bitfield.isAllOn());
      unit.expect(0xFF, 0xFF&bitfield.getBinary()[0]);
      unit.expect(0xFC, 0xFF&bitfield.getBinary()[8]);
    }); 
    
    unit.test("test_isAllOnPerByte", () {
      Bitfield bitfield = new Bitfield(20);
      unit.expect(true, bitfield.isAllOnPerByte(0));
      unit.expect(true, bitfield.isAllOnPerByte(1));
      unit.expect(true, bitfield.isAllOnPerByte(2));
      bitfield.zeroClear();
      unit.expect(false, bitfield.isAllOnPerByte(0));
      unit.expect(false, bitfield.isAllOnPerByte(1));
      unit.expect(false, bitfield.isAllOnPerByte(2));
      bitfield.setIsOn(0, true);
      unit.expect(false, bitfield.isAllOnPerByte(0));
      unit.expect(false, bitfield.isAllOnPerByte(1));
      unit.expect(false, bitfield.isAllOnPerByte(2));
      for(int i=0;i<8;i++) {
        bitfield.setIsOn(0+i, true);
      }
      unit.expect(true, bitfield.isAllOnPerByte(0));
      unit.expect(false, bitfield.isAllOnPerByte(1));
      unit.expect(false, bitfield.isAllOnPerByte(2));
      
      bitfield.setIsOn(10, true);
      unit.expect(true, bitfield.isAllOnPerByte(0));
      unit.expect(false, bitfield.isAllOnPerByte(1));
      unit.expect(false, bitfield.isAllOnPerByte(2));
      for(int i=0;i<8;i++) {
        bitfield.setIsOn(8+i, true);
      }
      unit.expect(true, bitfield.isAllOnPerByte(0));
      unit.expect(true, bitfield.isAllOnPerByte(1));
      unit.expect(false, bitfield.isAllOnPerByte(2));

      bitfield.setIsOn(19, true);
      unit.expect(true, bitfield.isAllOnPerByte(0));
      unit.expect(true, bitfield.isAllOnPerByte(1));
      unit.expect(false, bitfield.isAllOnPerByte(2));
      for(int i=0;i<8;i++) {
        bitfield.setIsOn(16+i, true);
      }
      unit.expect(true, bitfield.isAllOnPerByte(0));
      unit.expect(true, bitfield.isAllOnPerByte(1));
      unit.expect(true, bitfield.isAllOnPerByte(2));
    });
    
    //
    //
    //
    
    unit.test("test_getPieceAtRandom", () {
      {
        Bitfield field = new Bitfield(0);
        unit.expect(-1, field.getOffPieceAtRandom());
      }
      {
        Bitfield field = new Bitfield(1);
        unit.expect(-1, field.getOffPieceAtRandom());
        field.setIsOn(0, false);
        unit.expect(0, field.getOffPieceAtRandom());
      }

      {
        Bitfield field = new Bitfield(3);
        unit.expect(-1, field.getOffPieceAtRandom());
        field.setIsOn(1, false);
        unit.expect(1, field.getOffPieceAtRandom());
        field.setIsOn(2, true);
        int i = field.getOffPieceAtRandom();
        unit.expect(true, (i==2||i==1?true:false));
      }
    });
    
    
    unit.test("test_getOffPieceAtRandom", () {
      {
        Bitfield field = new Bitfield(0);
        unit.expect(-1, field.getOnPieceAtRandom());
      }
      {
        Bitfield field = new Bitfield(1);
        unit.expect(0, field.getOnPieceAtRandom());
        field.setIsOn(0, false);
        unit.expect(-1, field.getOnPieceAtRandom());
      }

      {
        Bitfield field = new Bitfield(3);
        int i = field.getOnPieceAtRandom();
        unit.expect(true, (i==0||i==1||i==2?true:false));

        field.setIsOn(1, false);
         i = field.getOnPieceAtRandom();
        unit.expect(true, (i==0||i==2?true:false));

        field.setIsOn(2, false);
         i = field.getOnPieceAtRandom();
        unit.expect(i, 0);
        
        field.setIsOn(0, false);
         i = field.getOnPieceAtRandom();
        unit.expect(-1, i);
      }
    });
  });
}
