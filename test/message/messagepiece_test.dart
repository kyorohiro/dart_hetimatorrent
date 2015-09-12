library test.messagepiece;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:convert' as convert;

void main() {
  ArrayBuilder builder = new ArrayBuilder();
  builder.appendIntList(ByteOrder.parseIntByte(9 + 5, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendByte(7);
  builder.appendIntList(ByteOrder.parseIntByte(10, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendIntList(ByteOrder.parseIntByte(100, ByteOrder.BYTEORDER_BIG_ENDIAN));
  builder.appendIntList([1, 2, 3, 4, 5]);

  unit.group('A group of tests', () {
 
    unit.test("decode/encode", () {
      EasyParser parser = new EasyParser(builder);
      return TMessagePiece.decode(parser).then((TMessagePiece message) {
        unit.expect(message.index, 10);
        unit.expect(message.begin, 100);
        unit.expect(message.content, [1, 2, 3, 4, 5]);
        return message.encode();
      }).then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("encode", () {
      TMessagePiece message = new TMessagePiece(10, 100, [1, 2, 3, 4, 5]);
      message.encode().then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });

    unit.test("error", () async {
      ArrayBuilder b = new ArrayBuilder.fromList(builder.toList().sublist(0, builder.size() - 1));
      b.fin();
      EasyParser parser = new EasyParser(b);

      bool isOK = false;
      try {
        TMessagePiece piece = await TMessagePiece.decode(parser);
        print("${piece}");
      } catch (e) {
        isOK = true;
      }
      unit.expect(true, isOK);
    });

    unit.test("decode and mem", () async {
      ArrayBuilder builder = new ArrayBuilder(bufferSize: 1024);
      builder.appendIntList(ByteOrder.parseIntByte(9 + 5, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(7);
      builder.appendIntList(ByteOrder.parseIntByte(10, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendIntList(ByteOrder.parseIntByte(100, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendIntList([1, 2, 3, 4, 5]);

      EasyParser parser = new EasyParser(builder);
      TMessagePiece message = await TMessagePiece.decode(parser);
      unit.expect(message.index, 10);
      unit.expect(message.begin, 100);
      unit.expect(message.content, [1, 2, 3, 4, 5]);
      List<int> data = await message.encode();
      unit.expect(builder.toList(), data);
      (parser.buffer as ArrayBuilder).clearInnerBuffer(parser.index, reuse:false);
      unit.expect(1006, (parser.buffer as ArrayBuilder).rawbuffer8.rawbuffer8.length);
    });
  });
}
