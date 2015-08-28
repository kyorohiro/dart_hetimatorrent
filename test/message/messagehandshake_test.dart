library test.messagehandshake;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  ArrayBuilder builder = new ArrayBuilder();
  builder.appendByte(19);
  builder.appendIntList(TMessageHandshake.ProtocolId, 0, TMessageHandshake.ProtocolId.length);
  builder.appendIntList([0,0,0,0,0,0,0,0], 0, 8);
  builder.appendIntList(convert.UTF8.encode("123456789A123456789B"), 0, 20);
  builder.appendIntList(convert.UTF8.encode("123456789C123456789D"), 0, 20);

  unit.group('A group of tests', () {
    unit.test("decode/encode", () {
      EasyParser parser = new EasyParser(builder);
      return TMessageHandshake.decode(parser).then((TMessageHandshake message) {
        unit.expect(message.protocolId, TMessageHandshake.ProtocolId);//message.
        unit.expect(message.reserved, [0,0,0,0,0,0,0,0]);//message.
        unit.expect(message.infoHash, convert.UTF8.encode("123456789A123456789B"));//message.
        unit.expect(message.peerId, convert.UTF8.encode("123456789C123456789D"));//message.
        return message.encode();
      }).then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });
    
    unit.test("encode", () {
      EasyParser parser = new EasyParser(builder);
      TMessageHandshake message = new TMessageHandshake(TMessageHandshake.ProtocolId, [0,0,0,0,0,0,0,0],
          convert.UTF8.encode("123456789A123456789B"), convert.UTF8.encode("123456789C123456789D"));

      message.encode().then((List<int> data) {
        unit.expect(builder.toList(), data);
      });
    });
    
    unit.test("error", () {
      ArrayBuilder b = new ArrayBuilder.fromList(builder.toList().sublist(0,builder.size()-1));
      b.fin();
      EasyParser parser = new EasyParser(b);

      TMessageHandshake.decode(parser).then((_) {
        unit.expect(true,false);
      }).catchError((e){
        unit.expect(true,true);
      });
    });
  });
}
