library test.messagechoke;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:convert' as convert;

void main() {

  ArrayBuilder builder = new ArrayBuilder();
  builder.appendIntList(ByteOrder.parseIntByte(1, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendByte(1);

  unit.group('A group of tests', () {
    unit.test("decode/encode", () {
      EasyParser parser = new EasyParser(builder);
      return MessageUnchoke.decode(parser).then((MessageUnchoke message) {
        return message.encode();
      }).then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });


    unit.test("encode", () {
      MessageUnchoke message = new MessageUnchoke();
      message.encode().then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("error", () {
      ArrayBuilder b = new ArrayBuilder.fromList(builder.toList().sublist(0,builder.size()-1));
      b.fin();
      EasyParser parser = new EasyParser(b);

      MessageUnchoke.decode(parser).then((_) {
        unit.expect(true,false);
      }).catchError((e){
        unit.expect(true,true);
      });
    });
  });
}
