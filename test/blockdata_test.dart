library blockdata.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("test_bitsizeIsZero", () {
      HetimaDataMemory data = new HetimaDataMemory([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]);
      Bitfield head = new Bitfield(5,clearIsOne:true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.read(0).then((ReadResult result) {
        unit.expect(result.buffer, [0,1,2,3,4]);
        return blockData.read(1);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [5,6,7,8,9]);
        return blockData.read(2);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [10,11,12,13,14]);
        return blockData.read(3);        
      }).then((ReadResult result) {
        unit.expect(result.buffer, [15,16,17,18,19]);
        return blockData.read(4);        
      }).then((ReadResult result) {
         unit.expect(result.buffer, [20]);
      });
    });
  });
}
