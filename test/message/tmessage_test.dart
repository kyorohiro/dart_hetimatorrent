library test.tmessage;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:convert' as convert;

void main() {
  ArrayBuilder builder = new ArrayBuilder();
  builder.appendIntList(ByteOrder.parseIntByte(5, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendByte(4);
  builder.appendIntList(ByteOrder.parseIntByte(10, ByteOrder.BYTEORDER_BIG_ENDIAN));

  unit.group('A group of tests', () {
    unit.test("decode/encode", () async {
      EasyParser parser = new EasyParser(builder);
      TorrentMessage message = await TorrentMessage.parseBasic(parser);
      unit.expect(0, parser.stack.length);
      unit.expect(message.id, 4);
      
    });
  });
}
