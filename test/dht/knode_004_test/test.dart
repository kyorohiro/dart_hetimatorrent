library knode001.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;
import 'dart:async';

void main() {
  unit.group('A group of tests', () {
    unit.test("retrive list 0", () {
      KNode a = new KNode(new HetimaSocketBuilderChrome(), intervalSecondForMaintenance: 1, verbose:true);
      a.addBootNode("192.168.1.26", 43611);
      a.addBootNode("192.168.1.26", 43611);
      a.start(ip:"192.168.1.26");
      return new Future.delayed(new Duration(seconds: 30)).then((_) {
        a.stop();
          print(" ${a.rootingtable.toInfo()}");
      });
      //});
    });
  });
}
