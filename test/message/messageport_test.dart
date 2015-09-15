library test.messageport;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:convert' as convert;

void main() {
  ArrayBuilder builder = new ArrayBuilder();
  builder.appendIntList(ByteOrder.parseIntByte(3, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendByte(9);
  List<int> d = ByteOrder.parseShortByte(10, ByteOrder.BYTEORDER_BIG_ENDIAN);
  builder.appendIntList(d);

  unit.group('A group of tests', () {
    unit.test("decode/encode", () {
      EasyParser parser = new EasyParser(builder);
      return TMessagePort.decode(parser).then((TMessagePort message) {
        unit.expect(message.port, 10);
        return message.encode();
      }).then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("encode", () {
      TMessagePort message = new TMessagePort(10);
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
        await TMessagePort.decode(parser);
      } catch (e) {
        isOk = true;
      }
      unit.expect(true, isOk);
    });
  });
}
