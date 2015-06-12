import 'package:unittest/unittest.dart' as unit;
import 'dart:async' as async;
import 'dart:typed_data' as type;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';

void main() {
  print("---");
  unit.group("", () {
    unit.test("compact=0 001", () {
      ShuffleLinkedList<PeerInfo> l = new ShuffleLinkedList();
      l.addLast(new PeerInfo([1,2,3], "a",[1,2,3,4], 80));
      unit.expect(l.length, 1);
    });
  });
}
