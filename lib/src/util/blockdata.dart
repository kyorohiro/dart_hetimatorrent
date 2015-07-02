library hetimatorrent.torrent.blockdata;

import 'dart:core';
import 'dart:async';

import 'package:hetimacore/hetimacore.dart';
import 'bitfield.dart';
import 'pieceinfo.dart';

class BlockData {
  Bitfield _head;
  HetimaData _data;
  int _blockSize;
  int _dataSize;

  int get blockSize => _blockSize;
  int get dataSize => _dataSize;

  List<int> get bitfield => _head.value;
  int get bitSize => _head.lengthPerBit();
  Map<int,PieceInfoList> _writePartData = {};

  BlockData(HetimaData data, Bitfield head, int blockSize, int dataSize) {
    if (dataSize == null) {
      _dataSize = head.lengthPerBit() * blockSize;
    } else {
      _dataSize = dataSize;
    }
    _data = data;
    _head = head;
    _blockSize = blockSize;
  }

  HetimaData getData() {
    return _data;
  }

  Future<WriteResult> writeBlock(List<int> data, int blockNum) {
    return new Future(() {
      
      if (data.length != _blockSize) {
        int lastLength = dataSize%blockSize;
        if(!(_head.lengthPerBit()-1 == blockNum && data.length == lastLength)) {
          throw  {};
        }
      }
      return _data.write(data, blockNum * _blockSize).then((WriteResult result) {
        _head.setIsOn(blockNum, true);
        {
          //
          //
          //
          if(_writePartData.containsKey(blockNum)){
            _writePartData.remove(blockNum);
          }
        }
        return result;
      });
    });
  }

  List<int> pieceInfoBlockNums() {
    return new List.from(_writePartData.keys);
  }

  PieceInfoList getPieceInfo(int blockNum) {
    return _writePartData[blockNum];
  }

  Future<WriteResult> writePartBlock(List<int> data, int blockNum, int begin, int length) {
    return new Future(() {
      int lastLength = dataSize%blockSize;
      if (begin+length > _blockSize || _head.lengthPerBit()-1 < blockNum ) {
          throw  {};
      }
      return _data.write(data.sublist(0,length), blockNum * _blockSize + begin).then((WriteResult result) {
        {
          //
          //
          PieceInfoList infoList = null;
          if(_writePartData.containsKey(blockNum)) {
            infoList = _writePartData[blockNum];
          } else {
            infoList = new PieceInfoList();
            _writePartData[blockNum] = infoList;
          }
          infoList.append(begin, begin+length);
          //
          //
          if(infoList.size() == 1 && infoList.getPieceInfo(0).start== 0 && infoList.getPieceInfo(0).end>=lastLength) {
            _head.setIsOn(blockNum, true);            
            _writePartData.remove(blockNum);
          }
          
        }
        return result;
      });
    });
  }

  Future<WriteResult> writeFullData(HetimaData data) {
    return new Future(() {
      int index = 0;
      a() {
        return data.read(index*blockSize, blockSize).then((ReadResult result) {
          return writeBlock(result.buffer, index);
        }).then((WriteResult result) {
          index++;
          if (index * blockSize < dataSize) {
            a();
          } else {
            return result;
          }
        });
      }
      return a();
    });
  }

  Future<ReadResult> readBlock(int blockNum) {
    return new Future(() {
      int length = _blockSize;
      if (blockNum * _blockSize + length > _dataSize) {
        length = _dataSize - blockNum * _blockSize;
      }

      if (_head.getIsOn(blockNum) == false) {
        return new ReadResult(ReadResult.NG, new List.filled(length, 0));
      }
      return _data.getLength().then((int currentDataLength) {
        if (blockNum * _blockSize + length > currentDataLength) {
          return new ReadResult(ReadResult.NG, new List.filled(length, 0));
        } else {
          return _data.read(blockNum * _blockSize, length);
        }
      });
    });
  }

  bool have(int blockNum) {
    return _head.getIsOn(blockNum);
  }
  
  bool haveAll() {
    return _head.isAllOn();
  }
}
