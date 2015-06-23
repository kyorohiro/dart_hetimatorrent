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


  Future write(List<int> data, int blockNum) {
    return new Future(() {
      
    });
  }
}