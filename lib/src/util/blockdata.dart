library hetimatorrent.torrent.blockdata;

import 'dart:core';
import 'dart:math';
import 'dart:async';

import 'package:hetimacore/hetimacore.dart';
import 'bitfield.dart';

class BlockData {

  Bitfield _head;
  HetimaData _data;
  int _blockSize;
  BlockData(HetimaData data, Bitfield head, int blockSize) {
    _data = data;
    _head = head;
    _blockSize = blockSize;
  }


  Future<WriteResult> write(List<int> data, int blockNum) {
    return new Future(() {
      if(data.length != _blockSize) {
        throw {};
      }
      return _data.write(data, blockNum*_blockSize).then((WriteResult result) {
        _head.setIsOn(0, true);
        return result;
      });
    });
  }

  Future<ReadResult> read(int blockNum) {
   return new Future((){
     if(_head.getIsOn(blockNum) == false) {
       return new ReadResult(ReadResult.NG, []);
     }
     return _data.read(blockNum*_blockSize, _blockSize);
   });
  }

}