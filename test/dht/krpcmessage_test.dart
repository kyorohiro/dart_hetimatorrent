library krpcmessage.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("ping request", () {
      KrpcPingQuery query = new KrpcPingQuery("aa", "abcdefghij0123456789");
      unit.expect("d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe", convert.UTF8.decode(query.messageAsBencode));

      EasyParser parser = new EasyParser(new HetimaFileToBuilder(new HetimaDataMemory(query.messageAsBencode)));
      return KrpcPingQuery.decode(parser).then((KrpcPingQuery q) {
        unit.expect("d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe", convert.UTF8.decode(q.messageAsBencode));
      });
    });
    unit.test("ping response", () {
      KrpcPingResponse query = new KrpcPingResponse("aa", "mnopqrstuvwxyz123456");
      unit.expect("d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re", convert.UTF8.decode(query.messageAsBencode));
      
      EasyParser parser = new EasyParser(new HetimaFileToBuilder(new HetimaDataMemory(query.messageAsBencode)));
      return KrpcPingResponse.decode(parser).then((KrpcPingResponse q) {
        unit.expect("d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re", convert.UTF8.decode(q.messageAsBencode));
      });
    });
    
    
    unit.test("'find node request", () {
      //find_node Query = {"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
      //bencoded = d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe      
      KrpcFindNodeQuery query = new KrpcFindNodeQuery("aa", "abcdefghij0123456789", "mnopqrstuvwxyz123456");
      unit.expect("d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe", convert.UTF8.decode(query.messageAsBencode));

      EasyParser parser = new EasyParser(new HetimaFileToBuilder(new HetimaDataMemory(query.messageAsBencode)));
      return KrpcFindNodeQuery.decode(parser).then((KrpcFindNodeQuery q) {
        unit.expect("d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe", convert.UTF8.decode(q.messageAsBencode));
      });
    });
    
    unit.test("'find node response", () {
      //Response = {"t":"aa", "y":"r", "r": {"id":"0123456789abcdefghij", "nodes": "def456..."}}
      //bencoded = d1:rd2:id20:0123456789abcdefghij5:nodes9:def456...e1:t2:aa1:y1:re 
      KrpcFindNodeResponse query = new KrpcFindNodeResponse("aa", "0123456789abcdefghij", new type.Uint8List.fromList(new List.filled(26, 0x61)));
      unit.expect("d1:rd2:id20:0123456789abcdefghij5:nodes26:aaaaaaaaaaaaaaaaaaaaaaaaaae1:t2:aa1:y1:re", convert.UTF8.decode(query.messageAsBencode));

      EasyParser parser = new EasyParser(new HetimaFileToBuilder(new HetimaDataMemory(query.messageAsBencode)));
      return KrpcFindNodeResponse.decode(parser).then((KrpcFindNodeResponse q) {
        unit.expect("d1:rd2:id20:0123456789abcdefghij5:nodes26:aaaaaaaaaaaaaaaaaaaaaaaaaae1:t2:aa1:y1:re", convert.UTF8.decode(q.messageAsBencode));
      });
    });
  });
  
}

//ping Query = {"t":"aa", "y":"q", "q":"ping", "a":{"id":"abcdefghij0123456789"}}
//bencoded = d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe
//Response = {"t":"aa", "y":"r", "r": {"id":"mnopqrstuvwxyz123456"}}
//bencoded = d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re
