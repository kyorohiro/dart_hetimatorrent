library pieceinfo.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("bencode: string", () {
      type.Uint8List out = Bencode.encode("test");
      unit.expect("4:test", convert.UTF8.decode(out.toList()));
      type.Uint8List text = Bencode.decode(out);
      unit.expect("test", convert.UTF8.decode(text.toList()));
    });
  });
}
