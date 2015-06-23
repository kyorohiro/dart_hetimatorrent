library bencode.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("bencode: string", () {
    type.Uint8List out = Bencode.encode("test");
    unit.expect("4:test", convert.UTF8.decode(out.toList()));
    type.Uint8List text = Bencode.decode(out);
    unit.expect("test", convert.UTF8.decode(text.toList()));
 });

  unit.test("bencode: number", () {
    type.Uint8List out = Bencode.encode(1024);
    unit.expect("i1024e", convert.UTF8.decode(out.toList()));
    num ret = Bencode.decode(out);
    unit.expect(1024, ret);
  });

//  {
//      type.Uint8List out = hetima.Bencode.encode(-10.24);
//      unit.expect("i-10.24e", convert.UTF8.decode(out.toList()));
//      num ret = hetima.Bencode.decode(out);
//      unit.expect(-10.24, ret);
//  }

  unit.test("bencode: list", () {
    List l = new List();
    l.add("test");
    l.add(1024);
    type.Uint8List out = Bencode.encode(l);
    unit.expect("l4:testi1024ee", convert.UTF8.decode(out.toList()));

    List list = Bencode.decode(out);
    unit.expect("test", convert.UTF8.decode(list[0].toList()));
    unit.expect(1024, list[1]);
  });

  unit.test("bencode: join", () {
    var pack = {};
    pack["action"] = "join";
    pack["mode"] = "broadcast";
    pack["id"] = Uuid.createUUID();
    type.Uint8List out = Bencode.encode(pack);

    unit.expect("d6:action4:join4:mode9:broadcast2:id36:" + pack["id"].toString() + "e", convert.UTF8.decode(out.toList()));
    Map m = Bencode.decode(out);
    unit.expect(pack["action"].toString(), convert.UTF8.decode(m["action"]).toString());
    unit.expect(pack["mode"].toString(), convert.UTF8.decode(m["mode"]).toString());
    unit.expect(pack["id"].toString(), convert.UTF8.decode(m["id"]).toString());
  });

  unit.test("bencode: dictionary", () {
    Map<String, Object> m = new Map();
    m["test"] = "test";
    m["value"] = 1024;
    type.Uint8List out = Bencode.encode(m);
    unit.expect("d4:test4:test5:valuei1024ee", convert.UTF8.decode(out.toList()));

    Map me = Bencode.decode(out);
    unit.expect("test", convert.UTF8.decode(me["test"].toList()));
    unit.expect(1024, me["value"]);
  });
 });
}
