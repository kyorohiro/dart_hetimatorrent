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
    unit.test("retrive list 0", () {
      KPeerInfo peerInfoA = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 1)));
      KAnnounceInfo announceInfoA = new KAnnounceInfo(peerInfoA, new List.filled(20, 1), 1);
      

      KPeerInfo peerInfoB = new KPeerInfo("127.0.0.1", 8080, new KId(new List.filled(20, 1)));
      KAnnounceInfo announceInfoB = new KAnnounceInfo(peerInfoB, new List.filled(20, 1), 1);

      unit.expect(peerInfoA, peerInfoB);
      unit.expect(announceInfoA, announceInfoB);
    });
  });
}
