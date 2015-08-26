library pieceinfo.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';

void main() {
  unit.group('A group of tests', () {
    unit.test("pieceinfo: 0-1", () {
      PieceInfo infoList = new PieceInfo();
      infoList.append(0, 1);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,0);
      unit.expect(infoList.getPieceInfo(0).end,1);
    });
    
    unit.test("pieceinfo: 100-200", () {
      PieceInfo infoList = new PieceInfo();
      infoList.append(100, 200);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,200);
    });

    unit.test("pieceinfo: 100-200,201-300", () {
      PieceInfo infoList = new PieceInfo();
      infoList.append(100, 200);
      infoList.append(201, 300);
      unit.expect(infoList.size(),2);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,200);
      unit.expect(infoList.getPieceInfo(1).start,201);
      unit.expect(infoList.getPieceInfo(1).end,300);
    });
    
    unit.test("pieceinfo: 100-200,200-300", () {
      PieceInfo infoList = new PieceInfo();
      infoList.append(100, 200);
      infoList.append(200, 300);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,300);
    });

    unit.test("pieceinfo: 100-200,201-300, 150-250", () {
      PieceInfo infoList = new PieceInfo();
      infoList.append(100, 200);
      infoList.append(201, 300);
      infoList.append(150, 250);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,300);
    });
    
    unit.test("pieceinfo: 100-200,201-300, 0-500", () {
      PieceInfo infoList = new PieceInfo();
      infoList.append(100, 200);
      infoList.append(201, 300);
      infoList.append(0, 500);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,0);
      unit.expect(infoList.getPieceInfo(0).end,500);
    });
    
    unit.test("pieceinfo: 100-200,150-180, 180-199", () {
      PieceInfo infoList = new PieceInfo();
      infoList.append(100, 200);
      infoList.append(150, 180);
      infoList.append(180, 199);
      unit.expect(infoList.size(),1);
      unit.expect(infoList.getPieceInfo(0).start,100);
      unit.expect(infoList.getPieceInfo(0).end,200);
    });
  });
}
