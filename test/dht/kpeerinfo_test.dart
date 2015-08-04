library kpeerinfo.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;
import 'dart:async';

void main() {
  unit.group('A group of tests', () {
    unit.test("same", () {
      KPeerInfo peerInfoA = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 1)));
      KGetPeerValue announceInfoA = new KGetPeerValue.fromString("127.0.0.1", 8080, new List.filled(20, 1));
      

      KPeerInfo peerInfoB = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 1)));
      KGetPeerValue announceInfoB = new KGetPeerValue.fromString("127.0.0.1", 8080, new List.filled(20, 1));

      unit.expect(peerInfoA, peerInfoB);
      unit.expect(announceInfoA, announceInfoB);
    });
    
    unit.test("diff", () {
      KPeerInfo peerInfoA = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 1)));
      KGetPeerValue announceInfoA = new KGetPeerValue.fromString("127.0.0.1", 8080, new List.filled(20, 1));
      

      KPeerInfo peerInfoB = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 2)));
      KGetPeerValue announceInfoB = new KGetPeerValue.fromString("127.0.0.1", 8080, new List.filled(20, 2));

      unit.expect(false, peerInfoA == peerInfoB);
      unit.expect(false, announceInfoA == announceInfoB);
    });
    
    unit.test("same", () {
      KGetPeerValue announceInfoA = new KGetPeerValue.fromString("127.0.0.1", 8080, new List.filled(20, 1));
      KGetPeerValue announceInfoB = new KGetPeerValue.fromString("127.0.0.2", 8081, new List.filled(20, 1));

      unit.expect(false, announceInfoA == announceInfoB);
    });
    
  });
}
