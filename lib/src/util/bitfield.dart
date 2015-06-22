library hetimatorrent.torrent.bitfield;

import 'dart:typed_data' as data;
import 'dart:convert' as convert;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;

class Bitfield {
  static final List<int> BIT = [0xFF, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE];

  int _bitSize = 0;
  List<int> _bitfieldData = [];

  Bitfield(int bitSize,{bool clearIsOne:true}) {
    this._bitSize = bitSize;
    if (bitSize % 8 != 0) {
      bitSize += 1;
    }
    _bitfieldData = new List.filled(bitSize, 0);
    if(clearIsOne) {
      oneClear();
    } else {
      zeroClear();
    }
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

  int lengthPerBit() {
    return _bitSize;
  }

  int lengthPerByte() {
    return _bitfieldData.length;
  }

  List<int> getBinary() {
    return _bitfieldData;
  }


  bool isAllOff() {
    int len =lengthPerBit();
    for(int i=0;i<len;i++) {
      if(getIsOn(i)) {
        return false;
      }
    }
    return true;
  }

  bool isAllOn() {
    int len =lengthPerBit();
    for(int i=0;i<len;i++) {
      if(!getIsOn(i)) {
        return false;
      }
    }
    return true;
  }
  
  bool getIsOn(int number) {
    int chunk = number~/8;
    int pos = number%8;
    // 8 0, 7 1, 3 3 7 7 
    if(_bitfieldData == null || chunk>=_bitfieldData.length) {
      return false;
    }
    if(((_bitfieldData[chunk]>>(7-pos))&0x01) == 0x01 ) {
      return true;
    } else {
      return false;
    }
  }

  void setIsOn(int number, bool on) {
    int chunk = number~/8;
    int pos = number%8;
    // 8 0, 7 1, 3 3 7 7 
    if(_bitfieldData == null || chunk>= _bitfieldData.length||number>=lengthPerBit()) {
      return;
    }

    int value = 0x01<<(7-pos);
    int v = _bitfieldData[chunk];
    if(on) {
      _bitfieldData[chunk] = v|value;
    } else {
      value = value^0xFFFFFFFF;
      _bitfieldData[chunk] = v&value;
    }
  }
}
