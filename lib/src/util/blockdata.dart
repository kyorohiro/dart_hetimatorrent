library hetimatorrent.util.blockdata;

import 'dart:core';
import 'dart:async';

import 'package:hetimacore/hetimacore.dart';
import 'bitfield.dart';
import 'bitfield_plus.dart';
import 'pieceinfo.dart';

/**
 * 
 * 
 */
class BlockData {
  Bitfield _head;
  HetimaData _data;
  int _blockSize;
  int _dataSize;
  Map<int, PieceInfo> _writePartData = {};
  Map<int, PieceInfo> _reservePartData = {};
  BitfieldInter _cacheHead = null;

  /**
   * 
   */
  int get blockSize => _blockSize;

  /**
   * 
   */
  int get dataSize => _dataSize;

  /**
   * 
   */
  List<int> get bitfield => _head.value;

  /**
   * 
   */
  int get bitSize => _head.lengthPerBit();

  /**
   *
   */
  Bitfield get rawHead => _head;

  /**
   * create BlockData
   */
  BlockData(HetimaData data, Bitfield head, int blockSize, int dataSize) {
    if (dataSize == null) {
      _dataSize = head.lengthPerBit() * blockSize;
    } else {
      _dataSize = dataSize;
    }
    _data = data;
    _head = head;
    _cacheHead = new BitfieldPlus(new Bitfield(head.lengthPerBit()));
    _blockSize = blockSize;
  }

  HetimaData getData() {
    return _data;
  }

  BitfieldInter isNotThrere(BitfieldInter ina, [BitfieldInter out = null]) {
    if (out == null) {
      out = _cacheHead;
    }
    Bitfield.relative(ina, _head, out);
    return out;
  }

  List<int> pieceInfoBlockNums() => new List.from(_writePartData.keys);
  PieceInfo getPieceInfo(int blockNum) => _writePartData[blockNum];

  List<int> reservePieceInfoBlockNums() => new List.from(_reservePartData.keys);
  PieceInfo getReservePieceInfo(int blockNum) => _reservePartData[blockNum];

  /**
   * 
   */
  Future<WriteResult> writeBlock(List<int> data, int blockNum, {strict: true}) async {
    return writePartBlock(data, blockNum, 0, data.length, strict: strict);
  }

  reservePartBlock(int blockNum, int begin, int length, {strict: true}) {
    if (strict == true && begin + length > _blockSize || _head.lengthPerBit() - 1 < blockNum) {
      throw {};
    }
    PieceInfo infoList = null;
    if (_reservePartData.containsKey(blockNum)) {
      infoList = _reservePartData[blockNum];
    } else {
      infoList = new PieceInfo();
      _reservePartData[blockNum] = infoList;
    }
    infoList.append(begin, begin + length);
  }

  /**
   * 
   */
  Future<WriteResult> writePartBlock(List<int> data, int blockNum, int begin, int length, {strict: true}) async {
    int targetBlockData = blockSize;
    if (blockNum == _head.lengthPerBit() - 1) {
      targetBlockData = dataSize % blockSize;
    }
    if (strict == true && begin + length > _blockSize || _head.lengthPerBit() - 1 < blockNum) {
      throw {};
    }
    WriteResult result = await _data.write(data.sublist(0, length), blockNum * _blockSize + begin);
    //
    //
    PieceInfo infoList = null;
    if (_writePartData.containsKey(blockNum)) {
      infoList = _writePartData[blockNum];
    } else {
      infoList = new PieceInfo();
      _writePartData[blockNum] = infoList;
    }
    infoList.append(begin, begin + length);
    reservePartBlock(blockNum, begin, length, strict:strict);

    //
    //
    if (infoList.size() == 1 && infoList.getPieceInfo(0).start == 0 && infoList.getPieceInfo(0).end >= targetBlockData) {
      _head.setIsOn(blockNum, true);
      _writePartData.remove(blockNum);
      _reservePartData.remove(blockNum);
    }
    return result;
  }

  /**
   * 
   */
  Future<WriteResult> writeFullData(HetimaData data) async {
    int index = 0;
    WriteResult result = null;
    do {
      ReadResult readResult = await data.read(index * blockSize, blockSize);
      result = await writeBlock(readResult.buffer, index);
      index++;
    } while (index * blockSize < dataSize);
    return result;
  }

  /**
   * 
   */
  Future<ReadResult> readBlock(int blockNum) async {
    int length = _blockSize;
    if (blockNum * _blockSize + length > _dataSize) {
      length = _dataSize - blockNum * _blockSize;
    }

    if (_head.getIsOn(blockNum) == false) {
      // todo throw error
      return new ReadResult(new List.filled(length, 0));
    }
    int currentDataLength = await _data.getLength();
    if (blockNum * _blockSize + length > currentDataLength) {
      // todo throw error
      return new ReadResult(new List.filled(length, 0));
    } else {
      return _data.read(blockNum * _blockSize, length);
    }
  }

  /**
   * 
   */
  BlockDataGetNextBlockPartResult getNextBlockPart(int targetBit, int downloadPieceLength, {BlockDataGetNextBlockPartResult out: null,bool userReserve:true}) {
    if (out == null) {
      out = new BlockDataGetNextBlockPartResult();
    }
    PieceInfo pieceInfo = null;
    if(userReserve) {
      pieceInfo = getReservePieceInfo(targetBit);
    } else {
      pieceInfo = getPieceInfo(targetBit);
    }
    int begin = 0;
    int end = 0;
    if (pieceInfo == null) {
      begin = 0;
      end = downloadPieceLength;
    } else {
      List<int> bl = pieceInfo.getFreeSpace(downloadPieceLength);
      begin = bl[0];
      end = bl[1];
    }
    if (end > _blockSize) {
      end = _blockSize;
    }
    if (_dataSize < targetBit * _blockSize + end) {
      end = end - ((targetBit * _blockSize + end) - _dataSize);
    }
    out.begin = begin;
    out.end = end;
    return out;
  }

  List<BlockDataGetNextBlockPartResult> getNextBlockParts(int targetBit, int downloadPieceLength, {bool userReserve:true}) {
    List<BlockDataGetNextBlockPartResult> ret = [];
    BlockDataGetNextBlockPartResult r1 = getNextBlockPart(targetBit, downloadPieceLength);
    ret.add(r1);
    int b = r1.begin;
    int e = r1.end;
    while ((targetBit * _blockSize + e) < _dataSize && e < _blockSize) {
      b = e;
      e = b + downloadPieceLength;
      if (e > _blockSize) {
        e = _blockSize;
      }
      if (_dataSize < targetBit * _blockSize + e) {
        e = e - ((targetBit * _blockSize + e) - _dataSize);
      }
      ret.add(new BlockDataGetNextBlockPartResult()
        ..begin = b
        ..end = e);
    }
    return ret;
  }

  /**
   * 
   */
  bool have(int blockNum) {
    return _head.getIsOn(blockNum);
  }

  /**
   * 
   */
  bool haveAll() {
    return _head.isAllOn();
  }
}

class BlockDataGetNextBlockPartResult {
  int begin = 0;
  int end = 0;
}
