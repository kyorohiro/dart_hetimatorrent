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
      l.addLast(new PeerInfo([1, 2, 3], "a", [1, 2, 3, 4], 80));
      unit.expect(l.length, 1);
      l.addLast(new PeerInfo([1, 2, 3], "a", [1, 2, 3, 4], 80));
      unit.expect(l.length, 1);
      l.addLast(new PeerInfo([1, 2, 3, 4], "a", [1, 2, 3, 4], 80));
      unit.expect(l.length, 2);
      l.removeHead();
      unit.expect(l.getShuffled(0).peerId, [1,2,3,4]);
      l.removeHead();
      unit.expect(l.length, 0);
      try {
        l.getShuffled(0);
        unit.expect(false,true);
      } catch(e) {
        unit.expect(true,true);
      }
    });
  });
}
