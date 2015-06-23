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
      return MessageHave.decode(parser).then((MessageHave message) {
        unit.expect(message.index, 10);
        return message.encode();
      }).then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });


    unit.test("encode", () {
      EasyParser parser = new EasyParser(builder);
      MessageHave message = new MessageHave(10);
      message.encode().then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("error", () {
      ArrayBuilder b = new ArrayBuilder.fromList(builder.toList().sublist(0,builder.size()-1));
      b.fin();
      EasyParser parser = new EasyParser(b);

      MessageHave.decode(parser).then((_) {
        unit.expect(true,false);
      }).catchError((e){
        unit.expect(true,true);
      });
    });
  });
}
