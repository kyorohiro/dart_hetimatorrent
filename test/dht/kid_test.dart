library krpcid.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("> >= < <=", () {
      KId idA = new KId(new List.filled(20, 0));
      KId idB = new KId(new List.filled(20, 1));
      unit.expect(true, idB > idA);
      unit.expect(true, idB >= idA);
      unit.expect(false, idB < idA);
      unit.expect(false, idB <= idA);
      //
      unit.expect(false, idB > idB);
      unit.expect(true, idB >= idB);
      unit.expect(false, idB < idB);
      unit.expect(true, idB <= idB);
    });

    unit.test("xor", () {
      KId idA = new KId(new List.filled(20, 255));
      KId idB = new KId(new List.filled(20, 1));
      KId idC = new KId(new List.filled(20, 254));

      unit.expect(true, idC == idB.xor(idA));
    });

    unit.test("rooting table index", () {
      KRootingTable table = new KRootingTable(8, new KId(new List.filled(20, 0)));
      unit.expect(0, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00])));
      unit.expect(1, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01])));
      unit.expect(2, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02])));
      unit.expect(2, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03])));
      unit.expect(3, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04])));
      unit.expect(3, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x05])));
      unit.expect(3, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x06])));
      unit.expect(3, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x07])));
      unit.expect(4, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08])));
      unit.expect(4, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08])));
      unit.expect(4, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08])));
      unit.expect(5, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x10])));
      unit.expect(6, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x20])));
      unit.expect(7, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40])));
      unit.expect(8, table.getRootingTabkeIndex(new KId([
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80])));
      unit.expect(160, table.getRootingTabkeIndex(new KId([
        0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00])));
      unit.expect(160, table.getRootingTabkeIndex(new KId([
        0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
        0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff])));
    });

    //
    //
    unit.test("xor", () {
      KRootingTable table = new KRootingTable(8, new KId(new List.filled(20, 0)));
      KId idA = new KId(new List.filled(20, 0));
      KId idB = new KId(new List.filled(20, 0xff));
      unit.expect(160, table.getRootingTabkeIndex(idA.xor(idB)));
      
      KId idC = new KId(new List.filled(20, 0^0x3));
      KId idD = new KId(new List.filled(20, 0xff^0x3));
      unit.expect(160, table.getRootingTabkeIndex(idC.xor(idD)));
      
      KId idE = new KId(new List.filled(20, 0^0xf3));
      KId idF = new KId(new List.filled(20, 0xff^0xf3));
      unit.expect(160, table.getRootingTabkeIndex(idE.xor(idF)));
    });
    
    //
    //
    unit.test("xor A", () {
      KId idA = new KId(new List.filled(20, 0));
      unit.expect(0x00, idA.xorToThe(0).value[19]);
      unit.expect(0x01, idA.xorToThe(1).value[19]);
      unit.expect(0x02, idA.xorToThe(2).value[19]);
      unit.expect(0x04, idA.xorToThe(3).value[19]);
      unit.expect(0x08, idA.xorToThe(4).value[19]);
      unit.expect(0x10, idA.xorToThe(5).value[19]);
      unit.expect(0x20, idA.xorToThe(6).value[19]);
      unit.expect(0x40, idA.xorToThe(7).value[19]);
      unit.expect(0x80, idA.xorToThe(8).value[19]);
      unit.expect(0x01, idA.xorToThe(9).value[18]);
      unit.expect(0x02, idA.xorToThe(10).value[18]);
      unit.expect(0x04, idA.xorToThe(11).value[18]);
      unit.expect(0x08, idA.xorToThe(12).value[18]);
      unit.expect(0x10, idA.xorToThe(13).value[18]);
      unit.expect(0x20, idA.xorToThe(14).value[18]);
      unit.expect(0x40, idA.xorToThe(15).value[18]);
      unit.expect(0x80, idA.xorToThe(16).value[18]);
      unit.expect(0x80, idA.xorToThe(160).value[0]);
    //retrievePath(int index)
    });
  });
}
