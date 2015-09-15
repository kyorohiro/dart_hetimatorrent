library test.messagecancel;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:convert' as convert;

void main() {
  ArrayBuilder builder = new ArrayBuilder();
  builder.appendIntList(ByteOrder.parseIntByte(13, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendByte(8);
  builder.appendIntList(ByteOrder.parseIntByte(10, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendIntList(ByteOrder.parseIntByte(100, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendIntList(ByteOrder.parseIntByte(10300, ByteOrder.BYTEORDER_BIG_ENDIAN));

  unit.group('A group of tests', () {
    unit.test("decode/encode", () {
      EasyParser parser = new EasyParser(builder);
      return TMessageCancel.decode(parser).then((TMessageCancel message) {
        unit.expect(message.index, 10);
        unit.expect(message.begin, 100);
        unit.expect(message.length, 10300);
        return message.encode();
      }).then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("encode", () {
      EasyParser parser = new EasyParser(builder);
      TMessageCancel message = new TMessageCancel(10, 100, 10300);
      message.encode().then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("error", () async {
      ArrayBuilder b = new ArrayBuilder.fromList(builder.toList().sublist(0, builder.size() - 1));
      b.fin();
      EasyParser parser = new EasyParser(b);

      bool isOk = false;
      try {
        await TMessageCancel.decode(parser);
      } catch (e) {
        isOk = true;
      }
      unit.expect(isOk, true);
    });
  });
}
