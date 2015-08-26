library blockdata.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';

void main() {
  unit.group('read test', () {
    unit.test("read basic true", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.readBlock(0).then((ReadResult result) {
        unit.expect(result.buffer, [0, 1, 2, 3, 4]);
        return blockData.readBlock(1);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [5, 6, 7, 8, 9]);
        return blockData.readBlock(2);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [10, 11, 12, 13, 14]);
        return blockData.readBlock(3);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [15, 16, 17, 18, 19]);
        return blockData.readBlock(4);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [20]);
      });
    });
    unit.test("read basic false", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: false);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.readBlock(0).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(1);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(2);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(3);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(4);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0]);
      });
    });

    unit.test("test zero", () {
      HetimaDataMemory data = new HetimaDataMemory([]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.readBlock(0).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(1);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(2);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(3);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(4);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0]);
      });
    });
    unit.test("test one bit", () {
      HetimaDataMemory data = new HetimaDataMemory([1]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.readBlock(0).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(4);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0]);
      });
    });
    unit.test("test one byte true", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.readBlock(0).then((ReadResult result) {
        unit.expect(result.buffer, [0, 1, 2, 3, 4]);
        return blockData.readBlock(4);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0]);
      });
    });
    unit.test("test one byte false", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4]);
      Bitfield head = new Bitfield(5, clearIsOne: false);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.readBlock(0).then((ReadResult result) {
        unit.expect(result.buffer, [0, 0, 0, 0, 0]);
        return blockData.readBlock(4);
      }).then((ReadResult result) {
        unit.expect(result.buffer, [0]);
      });
    });
  });

  unit.group('write test', () {
    unit.test("basic true", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.writeBlock([100, 101, 102, 103, 104], 1).then((WriteResult r) {
        return blockData.readBlock(0).then((ReadResult result) {
          unit.expect(result.buffer, [0, 1, 2, 3, 4]);
          return blockData.readBlock(1);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [100, 101, 102, 103, 104]);
          return blockData.readBlock(2);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [10, 11, 12, 13, 14]);
          return blockData.readBlock(3);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [15, 16, 17, 18, 19]);
          return blockData.readBlock(4);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [20]);
        });
      });
    });

    unit.test("basic false", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: false);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.writeBlock([100, 101, 102, 103, 104], 1).then((WriteResult r) {
        return blockData.readBlock(0).then((ReadResult result) {
          unit.expect(result.buffer, [0, 0, 0, 0, 0]);
          return blockData.readBlock(1);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [100, 101, 102, 103, 104]);
          return blockData.readBlock(2);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [0, 0, 0, 0, 0]);
          return blockData.readBlock(3);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [0, 0, 0, 0, 0]);
          return blockData.readBlock(4);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [0]);
        });
      });
    });

    unit.test("end", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: false);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.writeBlock([100, 101, 102, 103, 104], 4).then((WriteResult r) {
        return blockData.readBlock(0).then((ReadResult result) {
          unit.expect(result.buffer, [0, 0, 0, 0, 0]);
          return blockData.readBlock(1);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [0, 0, 0, 0, 0]);
          return blockData.readBlock(2);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [0, 0, 0, 0, 0]);
          return blockData.readBlock(3);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [0, 0, 0, 0, 0]);
          return blockData.readBlock(4);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [100]);
        });
      });
    });
  });

  unit.group('write full test', () {
    unit.test("basic true", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: false);
      BlockData blockData = new BlockData(new HetimaDataMemory([]), head, 5, 21);
      return blockData.writeFullData(data).then((WriteResult result) {
        return blockData.readBlock(0).then((ReadResult result) {
          unit.expect(result.buffer, [0, 1, 2, 3, 4]);
          return blockData.readBlock(1);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [5, 6, 7, 8, 9]);
          return blockData.readBlock(2);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [10, 11, 12, 13, 14]);
          return blockData.readBlock(3);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [15, 16, 17, 18, 19]);
          return blockData.readBlock(4);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [20]);
        });
      });
    });
  });

  //
  //
  //
  unit.group('write part test', () {
    unit.test("basic true", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.writePartBlock([100, 101, 102, 103, 104], 1, 1, 3).then((WriteResult r) {
        return blockData.readBlock(0).then((ReadResult result) {
          unit.expect(result.buffer, [0, 1, 2, 3, 4]);
          return blockData.readBlock(1);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [5, 100, 101, 102, 9]);
          return blockData.readBlock(2);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [10, 11, 12, 13, 14]);
          return blockData.readBlock(3);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [15, 16, 17, 18, 19]);
          return blockData.readBlock(4);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [20]);
        }).then((_) {
          unit.expect(blockData.pieceInfoBlockNums().length, 1);
          unit.expect(blockData.getPieceInfo(1).getPieceInfo(0).start, 1);
          unit.expect(blockData.getPieceInfo(1).getPieceInfo(0).end, 4);
        });
      }).then((_) {
        return blockData.writePartBlock([100, 101, 102, 103, 104], 1, 0, 3).then((WriteResult r) {
          unit.expect(blockData.pieceInfoBlockNums().length, 1);
          return blockData.writePartBlock([100, 101, 102, 103, 104], 1, 3, 2);
        }).then((WriteResult r) {
          unit.expect(blockData.pieceInfoBlockNums().length, 0);
          return blockData.readBlock(1);
        }).then((ReadResult r) {
          unit.expect(r.buffer, [100, 101, 102, 100, 101]);
        });
      });
    });

    unit.test("basic true --B-- ", () {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      return blockData.writePartBlock([100, 101, 102, 103, 104], 1, 1, 3).then((WriteResult r) {
        return blockData.readBlock(0).then((ReadResult result) {
          unit.expect(result.buffer, [0, 1, 2, 3, 4]);
          return blockData.readBlock(1);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [5, 100, 101, 102, 9]);
          return blockData.readBlock(2);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [10, 11, 12, 13, 14]);
          return blockData.readBlock(3);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [15, 16, 17, 18, 19]);
          return blockData.readBlock(4);
        }).then((ReadResult result) {
          unit.expect(result.buffer, [20]);
        }).then((_) {
          unit.expect(blockData.pieceInfoBlockNums().length, 1);
          unit.expect(blockData.getPieceInfo(1).getPieceInfo(0).start, 1);
          unit.expect(blockData.getPieceInfo(1).getPieceInfo(0).end, 4);
        });
      }).then((_) {
          return blockData.writePartBlock([100, 101, 102, 103, 104], 1, 0, 5);
        }).then((WriteResult r) {
          unit.expect(blockData.pieceInfoBlockNums().length, 0);
          return blockData.readBlock(1);
        }).then((ReadResult r) {
          unit.expect(r.buffer, [100, 101, 102, 103, 104]);
        });
    });
  });
}
