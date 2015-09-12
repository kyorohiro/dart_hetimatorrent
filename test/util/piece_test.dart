library peerinfo.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'dart:math';

void main() {
  unit.group('Piece Test', () {
    unit.test("pieceinfo: 0-1", () {
      BlockData blockData = new BlockData(new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), null, 2, 5);
      TorrentClientPeerInfoEmpty info = new TorrentClientPeerInfoEmpty();
      {
        info.bitfieldToMe = new Bitfield(3)..oneClear();
        TorrentClientPieceTest pieceTest = new TorrentClientPieceTest(blockData.rawHead, 2);
        TorrentClientPieceTestResultA r = pieceTest.interestTest(blockData, info);
        unit.expect(r.interested.length, 1);
        unit.expect(r.notinterested.length, 0);
      }
      {
        info.bitfieldToMe = new Bitfield(3)..zeroClear();
        TorrentClientPieceTest pieceTest = new TorrentClientPieceTest(blockData.rawHead, 2);
        TorrentClientPieceTestResultA r = pieceTest.interestTest(blockData, info);
        unit.expect(r.interested.length, 0);
        unit.expect(r.notinterested.length, 1);
      }
    });
  });
}
