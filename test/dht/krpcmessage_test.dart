library krpcmessage.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("ping request", () {
      KrpcMessage query = KrpcPing.createQuery(convert.UTF8.encode("abcdefghij0123456789"));
      String expect = "d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t${query.transactionIdAsString.length}:${query.transactionIdAsString}1:y1:qe";
      unit.expect(expect, convert.UTF8.decode(query.messageAsBencode));
      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect(expect, convert.UTF8.decode(q.messageAsBencode));
      });
    });

    unit.test("ping response", () {
      KrpcMessage query = KrpcPing.createResponse(convert.UTF8.encode("mnopqrstuvwxyz123456"), convert.UTF8.encode("aa"));
      unit.expect("d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re", convert.UTF8.decode(query.messageAsBencode));
      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect("d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re", convert.UTF8.decode(q.messageAsBencode));
      });
    });

    unit.test("'find node request", () {
      //find_node Query = {"t":"aa", "y":"q", "q":"find_node", "a": {"id":"abcdefghij0123456789", "target":"mnopqrstuvwxyz123456"}}
      //bencoded = d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t2:aa1:y1:qe
      KrpcMessage query = KrpcFindNode.createQuery(convert.UTF8.encode("abcdefghij0123456789"), convert.UTF8.encode("mnopqrstuvwxyz123456"));
      String expect = "d1:ad2:id20:abcdefghij01234567896:target20:mnopqrstuvwxyz123456e1:q9:find_node1:t${query.transactionIdAsString.length}:${query.transactionIdAsString}1:y1:qe";
      unit.expect(expect, convert.UTF8.decode(query.messageAsBencode));

      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect(expect, convert.UTF8.decode(q.messageAsBencode));
      });
    });

    unit.test("'find node response", () {
      //Response = {"t":"aa", "y":"r", "r": {"id":"0123456789abcdefghij", "nodes": "def456..."}}
      //bencoded = d1:rd2:id20:0123456789abcdefghij5:nodes9:def456...e1:t2:aa1:y1:re
      KrpcMessage query = KrpcFindNode.createResponse(new type.Uint8List.fromList(new List.filled(26, 0x61)), convert.UTF8.encode("0123456789abcdefghij"), convert.UTF8.encode("aa"));
      unit.expect("d1:rd2:id20:0123456789abcdefghij5:nodes26:aaaaaaaaaaaaaaaaaaaaaaaaaae1:t2:aa1:y1:re", convert.UTF8.decode(query.messageAsBencode));

      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect("d1:rd2:id20:0123456789abcdefghij5:nodes26:aaaaaaaaaaaaaaaaaaaaaaaaaae1:t2:aa1:y1:re", convert.UTF8.decode(q.messageAsBencode));
      });
    });

    //
    //
    unit.test("'announce request", () {
      // announce_peers Query = {"t":"aa", "y":"q", "q":"announce_peer", "a": {"id":"abcdefghij0123456789", "implied_port": 1, "info_hash":"mnopqrstuvwxyz123456", "port": 6881, "token": "aoeusnth"}}
      // bencoded = d1:ad2:id20:abcdefghij01234567899:info_hash20:mnopqrstuvwxyz1234564:porti6881e5:token8:aoeusnthe1:q13:announce_peer1:t2:aa1:y1:qe
      KrpcMessage query = KrpcAnnounce.createQuery(convert.UTF8.encode("abcdefghij0123456789"), 1, convert.UTF8.encode("mnopqrstuvwxyz123456"), 8080, convert.UTF8.encode("aoeusnth"));
      String expect = "d1:ad2:id20:abcdefghij01234567899:info_hash20:mnopqrstuvwxyz12345612:implied_porti1e4:porti8080e5:token8:aoeusnthe1:q13:announce_peer1:t${query.transactionIdAsString.length}:${query.transactionIdAsString}1:y1:qe";
      unit.expect(expect, convert.UTF8.decode(query.messageAsBencode));

      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect(expect, convert.UTF8.decode(q.messageAsBencode));
      });
    });

    //
    //
    unit.test("'announce response", () {
      //Response = {"t":"aa", "y":"r", "r": {"id":"mnopqrstuvwxyz123456"}}
      //bencoded = d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re
      KrpcMessage query = KrpcAnnounce.createResponse(convert.UTF8.encode("aa"), convert.UTF8.encode("mnopqrstuvwxyz123456"));
      unit.expect("d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re", convert.UTF8.decode(query.messageAsBencode));

      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect("d1:rd2:id20:mnopqrstuvwxyz123456e1:t2:aa1:y1:re", convert.UTF8.decode(q.messageAsBencode));
      });
    });

    //
    //
    unit.test("'get peers request", () {
      //get_peers Query = {"t":"aa", "y":"q", "q":"get_peers", "a": {"id":"abcdefghij0123456789", "info_hash":"mnopqrstuvwxyz123456"}}
      //bencoded = d1:ad2:id20:abcdefghij01234567899:info_hash20:mnopqrstuvwxyz123456e1:q9:get_peers1:t2:aa1:y1:qe
      KrpcMessage query = KrpcGetPeers.createQuery(convert.UTF8.encode("abcdefghij0123456789"), convert.UTF8.encode("mnopqrstuvwxyz123456"));
      String expect = "d1:ad2:id20:abcdefghij01234567899:info_hash20:mnopqrstuvwxyz123456e1:q9:get_peers1:t${query.transactionIdAsString.length}:${query.transactionIdAsString}1:y1:qe";
      unit.expect(expect, convert.UTF8.decode(query.messageAsBencode));

      EasyParser parser = new EasyParser(new HetimaFileToBuilder(new HetimaDataMemory(query.messageAsBencode)));
      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect(expect, convert.UTF8.decode(q.messageAsBencode));
      });
    });

    //
    //
    unit.test("'get peers response A", () {
      // Response with peers = {"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "values": ["axje.u", "idhtnm"]}}
      // bencoded = d1:rd2:id20:abcdefghij01234567895:token8:aoeusnth6:valuesl6:axje.u6:idhtnmee1:t2:aa1:y1:re
      KrpcMessage query = KrpcGetPeers.createResponseWithPeers(
          convert.UTF8.encode("aa"), convert.UTF8.encode("abcdefghij0123456789"), convert.UTF8.encode("aoeusnth"),
          [convert.UTF8.encode("axje.u"), convert.UTF8.encode("idhtnm")]);
      String expect = "d1:rd2:id20:abcdefghij01234567895:token8:aoeusnth6:valuesl6:axje.u6:idhtnmee1:t${query.transactionIdAsString.length}:${query.transactionIdAsString}1:y1:re";

      unit.expect(expect, convert.UTF8.decode(query.messageAsBencode));
      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect(expect, convert.UTF8.decode(q.messageAsBencode));
      });
    });

    unit.test("'get peers response B", () {
      // Response with closest nodes = {"t":"aa", "y":"r", "r": {"id":"abcdefghij0123456789", "token":"aoeusnth", "nodes": "def456..."}}
      // bencoded = d1:rd2:id20:abcdefghij01234567895:nodes9:def456...5:token8:aoeusnthe1:t2:aa1:y1:re
      KrpcMessage query = KrpcGetPeers.createResponseWithClosestNodes(
          convert.UTF8.encode("aa"), 
          convert.UTF8.encode("abcdefghij0123456789"), 
          convert.UTF8.encode("aoeusnth"), new type.Uint8List.fromList(new List.filled(26, 0x61)));
      unit.expect("d1:rd2:id20:abcdefghij01234567895:nodes26:aaaaaaaaaaaaaaaaaaaaaaaaaa5:token8:aoeusnthe1:t2:aa1:y1:re", convert.UTF8.decode(query.messageAsBencode));

      return KrpcMessage.decode(query.messageAsBencode).then((KrpcMessage q) {
        unit.expect("d1:rd2:id20:abcdefghij01234567895:nodes26:aaaaaaaaaaaaaaaaaaaaaaaaaa5:token8:aoeusnthe1:t2:aa1:y1:re", convert.UTF8.decode(q.messageAsBencode));
      });
    });

    unit.test("error response", () {
      KrpcMessage response = KrpcError.createResponse(convert.UTF8.encode("aa"), KrpcMessage.GENERIC_ERROR);
      unit.expect(response.errorCode, KrpcMessage.GENERIC_ERROR);
      unit.expect(response.transactionIdAsString, "aa");
      unit.expect(response.errorMessageAsString, KrpcError.errorDescription(KrpcMessage.GENERIC_ERROR));
    });
  });
}
