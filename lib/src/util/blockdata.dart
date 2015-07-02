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
  Map<int,PieceInfoList> _writeData = {};

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
          if(_writeData.containsKey(blockNum)){
            _writeData.remove(blockNum);
          }
        }
        return result;
      });
    });
  }

  Future<WriteResult> writePartBlock(List<int> data, int blockNum, int begin, int length) {
    return new Future(() {
      
      if (data.length != _blockSize) {
        int lastLength = dataSize%blockSize;
        if(!(_head.lengthPerBit()-1 == blockNum && data.length == lastLength)) {
          throw  {};
        }
      }
      return _data.write(data, blockNum * _blockSize).then((WriteResult result) {
        {
          //
          //
          PieceInfoList infoList = null;
          if(_writeData.containsKey(blockNum)) {
            infoList = _writeData[blockNum];
          } else {
            infoList = new PieceInfoList();
          }
          infoList.append(begin, begin+length);
          //
          //
          if(infoList.size() == 1 && infoList.getPieceInfo(0).start== 0 && infoList.getPieceInfo(0).end==_blockSize) {
            _head.setIsOn(blockNum, true);            
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
}
