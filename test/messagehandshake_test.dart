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
      builder.appendIntList([0,0,0,0,0,0,0,0], 0, 8);
      builder.appendIntList(convert.UTF8.encode("123456789A123456789B"), 0, 20);
      builder.appendIntList(convert.UTF8.encode("123456789C123456789D"), 0, 20);
      EasyParser parser = new EasyParser(builder);
      return MessageHandshake.decode(parser).then((MessageHandshake message) {
        unit.expect(message.protocolId, MessageHandshake.ProtocolId);//message.
        unit.expect(message.reserved, [0,0,0,0,0,0,0,0]);//message.
        unit.expect(message.infoHash, convert.UTF8.encode("123456789A123456789B"));//message.
        unit.expect(message.peerId, convert.UTF8.encode("123456789C123456789D"));//message.
      });
    });
  });
}
