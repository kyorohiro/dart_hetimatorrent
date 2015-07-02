library pieceinfo.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data' as type;
import 'dart:convert' as convert;

void main() {
  unit.group('A group of tests', () {
    unit.test("pieceinfo: 0-1", () {
      PieceInfoList infoList = new PieceInfoList();
      infoList.append(0, 1);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,0);
      unit.expect(infoList.getPieceInfo(0).end,1);
    });
    
    unit.test("pieceinfo: 100-200", () {
      PieceInfoList infoList = new PieceInfoList();
      infoList.append(100, 200);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,200);
    });

    unit.test("pieceinfo: 100-200,201-300", () {
      PieceInfoList infoList = new PieceInfoList();
      infoList.append(100, 200);
      infoList.append(201, 300);
      unit.expect(infoList.size(),2);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,200);
      unit.expect(infoList.getPieceInfo(1).start,201);
      unit.expect(infoList.getPieceInfo(1).end,300);
    });
    
    unit.test("pieceinfo: 100-200,200-300", () {
      PieceInfoList infoList = new PieceInfoList();
      infoList.append(100, 200);
      infoList.append(200, 300);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,300);
    });

    unit.test("pieceinfo: 100-200,201-300, 150-250", () {
      PieceInfoList infoList = new PieceInfoList();
      infoList.append(100, 200);
      infoList.append(201, 300);
      infoList.append(150, 250);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,300);
    });
  });
}
