library test.tmessage;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:convert' as convert;
import 'dart:typed_data';

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
  
  unit.group('B group of tests', () {
    unit.test("decode non buffer", () async {
      ArrayBuilder builder = new ArrayBuilder();
      // bitfield
      List<int> bitfield = [0xf0,0xff,0x0f];
      builder.appendIntList(ByteOrder.parseIntByte(bitfield.length+1,ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(5);
      builder.appendIntList(bitfield);
      // unchoke
      builder.appendIntList(ByteOrder.parseIntByte(1, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(1);

      Uint8List buffer = null;
      EasyParser parser = new EasyParser(builder);
      TorrentMessage message1 = await TorrentMessage.parseBasic(parser,buffer:buffer);
      unit.expect(0, parser.stack.length);
      unit.expect(message1.id, TorrentMessage.SIGN_BITFIELD);
      
      TorrentMessage message2 = await TorrentMessage.parseBasic(parser,buffer:buffer);
      unit.expect(0, parser.stack.length);
      unit.expect(message2.id, TorrentMessage.SIGN_UNCHOKE);
    });

    unit.test("decode use buffer", () async {
      ArrayBuilder builder = new ArrayBuilder();
      // bitfield
      List<int> bitfield = [0xf0,0xff,0x0f];
      builder.appendIntList(ByteOrder.parseIntByte(bitfield.length+1,ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(5);
      builder.appendIntList(bitfield);
      // unchoke
      builder.appendIntList(ByteOrder.parseIntByte(1, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(1);

      Uint8List buffer = new Uint8List(1024*16);
      EasyParser parser = new EasyParser(builder);
      TorrentMessage message1 = await TorrentMessage.parseBasic(parser,buffer:buffer);
      unit.expect(0, parser.stack.length);
      unit.expect(message1.id, TorrentMessage.SIGN_BITFIELD);
      
      TorrentMessage message2 = await TorrentMessage.parseBasic(parser,buffer:buffer);
      unit.expect(0, parser.stack.length);
      unit.expect(message2.id, TorrentMessage.SIGN_UNCHOKE);
    });
  });


}
