library bitfield.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data';

void main() {
  unit.group('A group of tests', () {
    unit.test("test_bitsizeIsZero", () async {
      BlockData data = new BlockData(new HetimaDataMemory(new Uint8List(100*1024*1000)), null, 100, 1024*1000);
      BitfieldPlus plus = new BitfieldPlus(data.rawHead);


      int i= 0;        List<int> buffer = new List.filled(100, 1);
      while(!plus.isAllOn()) {
        int id = plus.getOffPieceAtRandom();
        data.getNextBlockParts(id, 20);

        await data.writeBlock(buffer, id);
        //plus.setIsOn(id, true);
        print("----------[A] ${id} ${i++}");
      }
    });
  });
}


