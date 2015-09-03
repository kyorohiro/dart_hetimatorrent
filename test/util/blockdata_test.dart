library blockdata.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:typed_data';
import 'dart:async';

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

    unit.test("basic true --etNextBlockPart-- ", () async {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      {
        BlockDataGetNextBlockPartResult ret = blockData.getNextBlockPart(0, 2);
        unit.expect(ret.begin, 0);
        unit.expect(ret.end, 2);
      }
      {
        BlockDataGetNextBlockPartResult ret = blockData.getNextBlockPart(0, 2);
        unit.expect(ret.begin, 0);
        unit.expect(ret.end, 2);
      }
      
      {
        await blockData.writePartBlock([1,2], 0, 0, 2);
        BlockDataGetNextBlockPartResult ret = blockData.getNextBlockPart(0, 2);
        unit.expect(ret.begin, 2);
        unit.expect(ret.end, 4);
      }
      {
        await blockData.writePartBlock([1,2], 0, 2, 2);
        BlockDataGetNextBlockPartResult ret = blockData.getNextBlockPart(0, 2);
        unit.expect(ret.begin, 4);
        unit.expect(ret.end, 5);
      }
    });

    unit.test("basic true --etNextBlockParts-- ", () async {
      HetimaDataMemory data = new HetimaDataMemory([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      Bitfield head = new Bitfield(5, clearIsOne: true);
      BlockData blockData = new BlockData(data, head, 5, 21);
      {
        List<BlockDataGetNextBlockPartResult> ret = blockData.getNextBlockParts(0, 2);
        unit.expect(ret.length, 3);
        unit.expect(ret[0].begin, 0);
        unit.expect(ret[1].begin, 2);
        unit.expect(ret[2].begin, 4);
        unit.expect(ret[0].end, 2);
        unit.expect(ret[1].end, 4);
        unit.expect(ret[2].end, 5);
      }
    });

    unit.test("BitfieldA", () {
      BitfieldSample a = new BitfieldSample(12);
      a[5] = true;
      a[10] = true;
      print("${a.toBytes()}");
    });
  });
}

class BitfieldSample {
  List<bool> _data = [];
  BitfieldSample(int length) {
    _data = new List.filled(length, false);
  }

  bool operator [](int idx) => _data[idx];
  void operator []=(int idx, bool value) {
    _data[idx] = value;
  }
  int get length => _data.length;

  List<int> toBytes() {
    int bytesLengths = _data.length ~/ 8 + (_data.length % 8 == 0 ? 0 : 1);
    Uint8List ret = new Uint8List(bytesLengths);
    for (int i = 0; i < _data.length; i++) {
      if (this[i] == true) {
        ret[i ~/ 8] |= 0x80 >> (7 - (i % 8));
      }
    }
    return ret;
  }
}

class BlockDataSample {
  BitfieldSample _info = null;
  HetimaData _data = null;
  int _blockSize = 0;
  int _fileSize = 0;
  BlockDataSample(int fileSize, int blockSize, HetimaData data) {
    _info = new BitfieldSample(fileSize ~/ blockSize + (fileSize % blockSize == 0 ? 0 : 1));
    _data = data;
    _blockSize = blockSize;
    _fileSize = fileSize;
  }

  bool operator [](int idx) => _info[idx];
  int get length => _info.length;

  Future<WriteResult> writeBlock(int index, List<int> data) async {
    WriteResult ret = await _data.write(data, index * _blockSize);
    _info[index] = true;
    return ret;
  }

  Future<ReadResult> readBlock(int index) async {
    int start = index * _blockSize;
    int end = (start + _blockSize > _fileSize ? _fileSize : start + _blockSize);
    return _data.read(start, end - start);
  }
}
