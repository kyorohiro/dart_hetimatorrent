import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart' as hetima;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'dart:typed_data' as type;
import 'dart:convert' as convert;
import 'dart:async';

void main() {

  unit.group("hetimabencode", (){
    unit.test("number", (){
      type.Uint8List out = hetima.Bencode.encode(1024);
      unit.expect("i1024e", convert.UTF8.decode(out.toList()));
      hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
      hetima.EasyParser parser = new hetima.EasyParser(builder);
      Future e = hetima.HetiBencode.decode(parser).then((Object o) {
        int v = o;
        unit.expect(v,1024);
      });
      builder.appendIntList(out, 0, out.length);
      return e;
    });

    unit.test("number e1", (){
      hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
      hetima.EasyParser parser = new hetima.EasyParser(builder);
      Future e = hetima.HetiBencode.decode(parser)
      .then((Object o) {
        unit.expect(true, false);
      }).catchError((e){
        unit.expect(true, true);
      });
      builder.appendString("i00");
      builder.fin();
      return e;
    });
  });
  unit.test("number e2", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    Future e = hetima.HetiBencode.decode(parser)
    .then((Object o) {
      unit.expect(true, false);
    }).catchError((e){
      unit.expect(true, true);
    });
    builder.appendString("i00x");
    return e;
  });

  unit.test("number e3", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBencode.decode(parser)
    .then((Object o) {
      unit.expect(true, false);
    }).catchError((e){
      unit.expect(true, true);
    });
    builder.appendString("000");
    builder.fin();
  });

  unit.test("string", (){
    type.Uint8List out = hetima.Bencode.encode("hetimatan");
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);

    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeString(parser).then((Object o) {
      String v = o;
      unit.expect(v, "hetimatan");
    });
    builder.appendIntList(out, 0, out.length);
    return e;
  });

  unit.test("string e1", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);

    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeString(parser).then((Object o) {
      unit.expect(true, false);
    }).catchError((e){
      unit.expect(true, true);
    });
    builder.appendString("3:ab");
    builder.fin();
    return e;
  });

  unit.test("string e2", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);

    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeString(parser).then((Object o) {
      unit.expect(true, false);
    }).catchError((e){
      unit.expect(true, true);
    });
    builder.appendString("3abc");
    builder.fin();
    return e;
  });
  
  unit.test("string e3", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);

    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeString(parser).then((Object o) {
      unit.expect(true, false);
    }).catchError((e){
      unit.expect(true, true);
    });
    builder.appendString(":abc");
    builder.fin();
    return e;
  });
  unit.test("list", (){
    List l = new List();
    l.add("test");
    l.add(1024);
    type.Uint8List out = hetima.Bencode.encode(l);
    unit.expect("l4:testi1024ee", convert.UTF8.decode(out.toList()));

    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeList(parser).then((List<Object> o) {
      unit.expect(convert.UTF8.decode(o[0]), "test");
      unit.expect(o[1],  1024);
    }).catchError((e) {

    });
    builder.appendIntList(out, 0, out.length);
    return e;
  });
  unit.test("list e1", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeList(parser).then((List<Object> o) {
      unit.expect(true, false);
    }).catchError((e) {
      unit.expect(true, true);
    });
    builder.appendString("l4:testi1024e");
    builder.fin();
  });

  unit.test("list e2", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeList(parser).then((List<Object> o) {
      unit.expect(true, false);
    }).catchError((e) {
      unit.expect(true, true);
    });
    builder.appendString("l4:test;1024ee");
    builder.fin();
  });

  unit.test("list e3", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeList(parser).then((List<Object> o) {
      unit.expect(true, false);
    }).catchError((e) {
      unit.expect(true, true);
    });
    builder.appendString("f4:testi1024ee");
    builder.fin();
  });

  unit.test("dictionary", (){

    Map<String, Object> m = new Map();
    m["test"] = "test";
    m["value"] = 1024;
    type.Uint8List out = hetima.Bencode.encode(m);
    unit.expect("d4:test4:test5:valuei1024ee", convert.UTF8.decode(out.toList()));

    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeDiction(parser).then((Map dict) {
      unit.expect(convert.UTF8.decode(dict["test"]),"test");
      unit.expect(dict["value"],1024);
    });
    builder.appendIntList(out, 0, out.length);
    return e;
  });

  unit.test("dictionary e1", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeDiction(parser).then((Map dict) {
      unit.expect(true, false);
    }).catchError((e) {
      unit.expect(true, true);
    });
    builder.appendString("d4:test4:test5:valuei1024e");
    builder.fin();
    return e;
  });

  unit.test("dictionary e2", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeDiction(parser).then((Map dict) {
      unit.expect(true, false);
    }).catchError((e) {
      unit.expect(true, true);
    });
    builder.appendString("d4:test4:test5:value1024ee");
    builder.fin();
    return e;
  });

  unit.test("dictionary e3", (){
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    Future e = decoder.decodeDiction(parser).then((Map dict) {
      unit.expect(true, false);
    }).catchError((e) {
      unit.expect(true, true);
    });
    builder.appendString("gg4:test4:test5:value1024ee");
    builder.fin();
    return e;
  });
}
