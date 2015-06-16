library test.messagehandshake;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("bencode: string", () {
      ArrayBuilder builder = new ArrayBuilder();
      builder.appendByte(19);
      builder.appendIntList(MessageHandshake.ProtocolId, 0, MessageHandshake.ProtocolId.length);
      builder.appendIntList(MessageHandshake.RESERVED, 0, MessageHandshake.RESERVED.length);
      builder.appendIntList(convert.UTF8.encode("123456789A123456789B"), 0, 20);
      builder.appendIntList(convert.UTF8.encode("123456789C123456789D"), 0, 20);
    });
  });
}
