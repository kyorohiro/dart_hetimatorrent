library test.messagehave;

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
    unit.test("decode/encode", () {
      EasyParser parser = new EasyParser(builder);
      return TMessageHave.decode(parser).then((TMessageHave message) {
        unit.expect(message.index, 10);
        return message.encode();
      }).then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("encode", () {
      EasyParser parser = new EasyParser(builder);
      TMessageHave message = new TMessageHave(10);
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
        await TMessageHave.decode(parser);
      } catch (e) {
        isOk = true;
      }
      unit.expect(true, isOk);
    });
  });
}
