library knodecommsimu.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;
import 'dart:async';

void main() {
  unit.group('A group of tests', () {
    unit.test("retrive list 0", () {
      KNodeCommSimu simuA = new KNodeCommSimu();
      simuA.bind("127.0.0.1", 8081);
      KNodeCommSimu simuB = new KNodeCommSimu();
      simuB.bind("127.0.0.2", 8082);
      Completer c = new Completer();
      simuB.onReceive().listen((HetiReceiveUdpInfo i) {
        unit.expect(i.remoteAddress,"127.0.0.1");
        unit.expect(i.remotePort, 8081);
        unit.expect(convert.UTF8.decode(i.data),"test");
        c.complete(null);
      });
      simuA.send(convert.UTF8.encode("test"), "127.0.0.2", 8082);
      return c.future;
    });
  });
}
