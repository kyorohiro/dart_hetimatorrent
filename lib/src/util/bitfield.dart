library hetimatorrent.torrent.bitfield;

import 'dart:typed_data' as data;
import 'dart:convert' as convert;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'dart:math';

class Bitfield {
  static final List<int> BIT = [0xFF, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE];

  int _bitSize = 0;
  List<int> _bitfieldData = [];
  List<int> _shuffleList = [0, 1, 2, 3, 4, 5, 6, 7];
  Random _rand = null;

  Bitfield(int bitSize, {bool clearIsOne: true, seed: null}) {
    if (seed == null) {
      _rand = new Random();
    } else {
      _rand = new Random(seed);
    }

    this._bitSize = bitSize;
    int byteSize = bitSize ~/ 8;
    if (bitSize % 8 != 0) {
      byteSize += 1;
    }
    _bitfieldData = new List.filled(byteSize, 0);
    if (clearIsOne) {
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
    int len = lengthPerBit();
    for (int i = 0; i < len; i++) {
      if (getIsOn(i)) {
        return false;
      }
    }
    return true;
  }

  bool isAllOn() {
    int len = lengthPerBit();
    for (int i = 0; i < len; i++) {
      if (!getIsOn(i)) {
        return false;
      }
    }
    return true;
  }

  bool getIsOn(int number) {
    int chunk = number ~/ 8;
    int pos = number % 8;
    // 8 0, 7 1, 3 3 7 7
    if (_bitfieldData == null || chunk >= _bitfieldData.length) {
      return false;
    }
    if (((_bitfieldData[chunk] >> (7 - pos)) & 0x01) == 0x01) {
      return true;
    } else {
      return false;
    }
  }

  void setIsOn(int number, bool on) {
    int chunk = number ~/ 8;
    int pos = number % 8;
    // 8 0, 7 1, 3 3 7 7
    if (_bitfieldData == null || chunk >= _bitfieldData.length || number >= lengthPerBit()) {
      return;
    }

    int value = 0x01 << (7 - pos);
    int v = _bitfieldData[chunk];
    if (on) {
      _bitfieldData[chunk] = v | value;
    } else {
      value = value ^ 0xFFFFFFFF;
      _bitfieldData[chunk] = v & value;
    }
  }

  bool isAllOnPerByte(int number) {
    int len = lengthPerByte();
    int last = lengthPerBit() % 8;

    if (number >= len) {
      return false;
    }
    if (number < (len - 1)) {
      if ((0xFF & _bitfieldData[number]) == 0xFF) {
        return true;
      } else {
        return false;
      }
    } else {
      if ((0xFF & _bitfieldData[number]) == (0xFF & BIT[last])) {
        return true;
      } else {
        return false;
      }
    }
  }

  bool isAllOffPerByte(int number) {
    int len = lengthPerByte();
    if (number >= len) {
      return false;
    }
    if ((0xFF & _bitfieldData[number]) == 0x00) {
      return true;
    } else {
      return false;
    }
  }

  int getOffPieceAtRandomPerByte(int numPerByte) {
    return getPieceAtRandomPerByte(numPerByte, true);
  }

  int getOnPieceAtRandomPerByte(int numPerByte) {
    return getPieceAtRandomPerByte(numPerByte, false);
  }

  //
  // TODO next work following method is wrong
  //
  int getPieceAtRandom(bool isOff) {
    int byteLength = lengthPerByte();
    if (byteLength <= 0) {
      return -1;
    }
    int ia = _rand.nextInt(byteLength);
    bool findedAtIA = false;
    for (int i = ia; i < byteLength; i++) {
      if (isOff) {
        if (!isAllOnPerByte(i)) {
          ia = i;
          findedAtIA = true;
          break;
        }
      } else {
        if (!isAllOffPerByte(i)) {
          ia = i;
          findedAtIA = true;
          break;
        }
      }
    }

    if (!findedAtIA) {
      for (int i = ia; i >= 0; i--) {
        if (isOff) {
          if (!isAllOnPerByte(i)) {
            ia = i;
            findedAtIA = true;
            break;
          }
        } else {
          if (!isAllOffPerByte(i)) {
            ia = i;
            findedAtIA = true;
            break;
          }
        }
      }
    }
    if (!findedAtIA) {
      return -1;
    }

    if (isOff) {
      return getOffPieceAtRandomPerByte(ia);
    } else {
      return getOnPieceAtRandomPerByte(ia);
    }
  }

  int getPieceAtRandomPerByte(int numPerByte, bool isOff) {
    int byteLength = lengthPerByte();
    if (byteLength <= 0) {
      return -1;
    }
    _shuffle(_shuffleList);

    int rn = 8;
    if (rn > (lengthPerBit() - numPerByte * 8)) {
      rn = (lengthPerBit() - numPerByte * 8);
    }
    for (int i = 0; i < 8; i++) {
      if ((numPerByte * 8 + _shuffleList[i]) < lengthPerBit() && isOff != getIsOn(numPerByte * 8 + _shuffleList[i])) {
        return (numPerByte * 8 + _shuffleList[i]);
      }
    }
    return -1;
  }

  void _shuffle(List<int> shufflelist) {
    int tmp1 = 0;
    int tmp2 = 0;
    for (int i = 0; i < 8; i++) {
      tmp1 = _rand.nextInt(8);
      tmp2 = shufflelist[i];
      shufflelist[i] = shufflelist[tmp1];
      shufflelist[tmp1] = tmp2;
    }
  }

  int getOffPieceAtRandom() {
    return getPieceAtRandom(true);
  }

  int getOnPieceAtRandom() {
    return getPieceAtRandom(false);
  }
}
