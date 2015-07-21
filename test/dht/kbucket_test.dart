library kbucket.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('kbucket', () {
    unit.test("> >= < <=", () {
      KBucket kbicket = new KBucket(20); 
      
      unit.expect(true, idB > idA);
    });
  });
}
