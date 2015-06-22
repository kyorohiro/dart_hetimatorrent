library hetimatorrent.torrent.bitfield;

import 'dart:typed_data' as data;
import 'dart:convert' as convert;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;

class Bitfield {
  static final List<int> BIT = [0xFF, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE];

  int _bitSize = 0;
  List<int> _bitfieldData = [];

  Bitfield(int bitSize) {
    this._bitSize = bitSize;
    if (bitSize % 8 != 0) {
      bitSize += 1;
    }
    _bitfieldData = new List.filled(bitSize, 0);
  }

  void oneClear() {
    int bitsize = _bitSize;
    int byteSize = bitsize ~/ 8;
    if ((bitsize % 8) != 0) {
      byteSize += 1;
    }
    for (int i = 0; i < _bitfieldData.length; i++) {
      _bitfieldData[i] = 0xFF;
    }
    if (_bitfieldData.length != 0) {
      _bitfieldData[byteSize - 1] = (BIT[bitsize % 8] & 0xFF);
    }
  }

  void zeroClear() {
    for (int i = 0; i < _bitfieldData.length; i++) {
      _bitfieldData[i] = 0;
    }
  }
}
