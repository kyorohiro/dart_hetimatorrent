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
      return MessagePort.decode(parser).then((MessagePort message) {
        unit.expect(message.port, 10);
        return message.encode();
      }).then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });


    unit.test("encode", () {
      MessagePort message = new MessagePort(10);
      message.encode().then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("error", () {
      ArrayBuilder b = new ArrayBuilder.fromList(builder.toList().sublist(0,builder.size()-1));
      b.fin();
      EasyParser parser = new EasyParser(b);

      MessagePort.decode(parser).then((_) {
        unit.expect(true,false);
      }).catchError((e){
        unit.expect(true,true);
      });
    });
  });
}
