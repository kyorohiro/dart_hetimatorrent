import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart' as hetima;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {

  hetima.HetiTest test = new hetima.HetiTest("t");

  {
    hetima.HetiTestTicket ticket = test.test("number", 3000);
    type.Uint8List out = hetima.Bencode.encode(1024);
    unit.expect("i1024e", convert.UTF8.decode(out.toList()));
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBencode.decode(parser).then((Object o) {
      int v = o;
      ticket.assertTrue("v=" + v.toString(), v == 1024);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendUint8List(out, 0, out.length);
  }
  {
    hetima.HetiTestTicket ticket = test.test("number e1", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBencode.decode(parser)
    .then((Object o) {
      ticket.assertTrue("", false);
    }).catchError((e){
      ticket.assertTrue("", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("i00");
    builder.fin();
  }
  {
    hetima.HetiTestTicket ticket = test.test("number e2", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBencode.decode(parser)
    .then((Object o) {
      ticket.assertTrue("", false);
    }).catchError((e){
      ticket.assertTrue("", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("i00x");
  }
  {
    hetima.HetiTestTicket ticket = test.test("number e3", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBencode.decode(parser)
    .then((Object o) {
      ticket.assertTrue("", false);
    }).catchError((e){
      ticket.assertTrue("", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("000");
    builder.fin();
  }
  {
    hetima.HetiTestTicket ticket = test.test("string", 3000);
    type.Uint8List out = hetima.Bencode.encode("hetimatan");
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);

    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeString(parser).then((Object o) {
      String v = o;
      ticket.assertTrue("v=" + v.toString(), v == "hetimatan");
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendUint8List(out, 0, out.length);
  }
  {
    hetima.HetiTestTicket ticket = test.test("string e1", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);

    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeString(parser).then((Object o) {
      ticket.assertTrue("", false);
    }).catchError((e){
      ticket.assertTrue("", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("3:ab");
    builder.fin();
  }
  {
    hetima.HetiTestTicket ticket = test.test("string e2", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);

    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeString(parser).then((Object o) {
      ticket.assertTrue("", false);
    }).catchError((e){
      ticket.assertTrue("", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("3abc");
    builder.fin();
  }
  {
    hetima.HetiTestTicket ticket = test.test("string e3", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);

    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeString(parser).then((Object o) {
      ticket.assertTrue("", false);
    }).catchError((e){
      ticket.assertTrue("", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString(":abc");
    builder.fin();
  }
  {
    hetima.HetiTestTicket ticket = test.test("list", 3000);
    List l = new List();
    l.add("test");
    l.add(1024);
    type.Uint8List out = hetima.Bencode.encode(l);
    unit.expect("l4:testi1024ee", convert.UTF8.decode(out.toList()));

    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeList(parser).then((List<Object> o) {
      ticket.assertTrue("v1=" + o[0].toString(), convert.UTF8.decode(o[0]) == "test");
      ticket.assertTrue("v2=" + o[1].toString(), o[1] == 1024);
    }).catchError((e) {

    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendUint8List(out, 0, out.length);
  }
  {
    hetima.HetiTestTicket ticket = test.test("list e1", 3000);

    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeList(parser).then((List<Object> o) {
      ticket.assertTrue("v1", false);
    }).catchError((e) {
      ticket.assertTrue("v1", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("l4:testi1024e");
    builder.fin();
  }
  {
    hetima.HetiTestTicket ticket = test.test("list e2", 3000);

    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeList(parser).then((List<Object> o) {
      ticket.assertTrue("v1", false);
    }).catchError((e) {
      ticket.assertTrue("v1", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("l4:test;1024ee");
    builder.fin();
  }

  {
    hetima.HetiTestTicket ticket = test.test("list e3", 3000);

    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeList(parser).then((List<Object> o) {
      ticket.assertTrue("v1", false);
    }).catchError((e) {
      ticket.assertTrue("v1", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("f4:testi1024ee");
    builder.fin();
  }
  {
    hetima.HetiTestTicket ticket = test.test("dictionary", 3000);

    Map<String, Object> m = new Map();
    m["test"] = "test";
    m["value"] = 1024;
    type.Uint8List out = hetima.Bencode.encode(m);
    unit.expect("d4:test4:test5:valuei1024ee", convert.UTF8.decode(out.toList()));

    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeDiction(parser).then((Map dict) {
      ticket.assertTrue("" + dict["test"].toString(), convert.UTF8.decode(dict["test"]) == "test");
      ticket.assertTrue("" + dict["value"].toString(), dict["value"] == 1024);
    }).catchError((e) {

    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendUint8List(out, 0, out.length);
  }

  {
    hetima.HetiTestTicket ticket = test.test("dictionary e1", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeDiction(parser).then((Map dict) {
      ticket.assertTrue("" + dict["test"].toString(), convert.UTF8.decode(dict["test"]) == "test");
      ticket.assertTrue("" + dict["value"].toString(), dict["value"] == 1024);
    }).catchError((e) {
      ticket.assertTrue("v1", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("d4:test4:test5:valuei1024e");
    builder.fin();
  }

  {
    hetima.HetiTestTicket ticket = test.test("dictionary e2", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeDiction(parser).then((Map dict) {
      ticket.assertTrue("" + dict["test"].toString(), convert.UTF8.decode(dict["test"]) == "test");
      ticket.assertTrue("" + dict["value"].toString(), dict["value"] == 1024);
    }).catchError((e) {
      ticket.assertTrue("v1", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("d4:test4:test5:value1024ee");
    builder.fin();
  }

  {
    hetima.HetiTestTicket ticket = test.test("dictionary e3", 3000);
    hetima.ArrayBuilder builder = new hetima.ArrayBuilder();
    hetima.EasyParser parser = new hetima.EasyParser(builder);
    hetima.HetiBdecoder decoder = new hetima.HetiBdecoder();
    decoder.decodeDiction(parser).then((Map dict) {
      ticket.assertTrue("" + dict["test"].toString(), convert.UTF8.decode(dict["test"]) == "test");
      ticket.assertTrue("" + dict["value"].toString(), dict["value"] == 1024);
    }).catchError((e) {
      ticket.assertTrue("v1", true);
    }).whenComplete(() {
      ticket.fin();
    });
    builder.appendString("gg4:test4:test5:value1024ee");
    builder.fin();
  }
}
