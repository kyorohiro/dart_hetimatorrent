library hetimatorrent.torrent.ddbitfield;

import 'dart:core';
import 'dart:math';
import 'bitfield.dart';

class DDBitfield extends BitfieldInter {
  Bitfield innerField = null;

  List<int> _shuffleList = [0, 1, 2, 3, 4, 5, 6, 7];
  Random _rand = null;

  DDBitfield(Bitfield bitfield,{int seed: null}) {
    innerField = bitfield;
    if (seed == null) {
      _rand = new Random();
    } else {
      _rand = new Random(seed);
    }
  }

  void change(Bitfield base) {
    innerField = base;
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
    int byteLength = innerField.lengthPerByte();
    if (byteLength <= 0) {
      return -1;
    }
    int ia = _rand.nextInt(byteLength);
    bool findedAtIA = false;
    for (int i = ia; i < byteLength; i++) {
      if (isOff) {
        if (!innerField.isAllOnPerByte(i)) {
          ia = i;
          findedAtIA = true;
          break;
        }
      } else {
        if (!innerField.isAllOffPerByte(i)) {
          ia = i;
          findedAtIA = true;
          break;
        }
      }
    }

    if (!findedAtIA) {
      for (int i = ia; i >= 0; i--) {
        if (isOff) {
          if (!innerField.isAllOnPerByte(i)) {
            ia = i;
            findedAtIA = true;
            break;
          }
        } else {
          if (!innerField.isAllOffPerByte(i)) {
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
    int byteLength = innerField.lengthPerByte();
    if (byteLength <= 0) {
      return -1;
    }
    _shuffle(_shuffleList);

    int rn = 8;
    if (rn > (innerField.lengthPerBit() - numPerByte * 8)) {
      rn = (innerField.lengthPerBit() - numPerByte * 8);
    }
    for (int i = 0; i < 8; i++) {
      if ((numPerByte * 8 + _shuffleList[i]) < innerField.lengthPerBit() && 
          isOff != innerField.getIsOn(numPerByte * 8 + _shuffleList[i])) {
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

  void update() {}

  @override
  List<int> getBinary() {
    return innerField.getBinary();
  }

  @override
  bool getIsOn(int number) {
    return innerField.getIsOn(number);
  }

  @override
  bool isAllOff() {
    return innerField.isAllOff();
  }

  @override
  bool isAllOffPerByte(int number) {
    return innerField.isAllOffPerByte(number);
  }

  @override
  bool isAllOn() {
    return innerField.isAllOn();
  }

  @override
  bool isAllOnPerByte(int number) {
    return innerField.isAllOnPerByte(number);
  }

  @override
  int lengthPerBit() {
    return innerField.lengthPerBit();
  }

  @override
  int lengthPerByte() {
    return innerField.lengthPerByte();
  }

  @override
  void oneClear() {
    return innerField.oneClear();
  }

  @override
  List<int> get rawValue => innerField.rawValue;

  @override
  void setIsOn(int number, bool on) {
    innerField.setIsOn(number, on);
  }

  @override
  List<int> get value => innerField.value;

  @override
  void writeBytes(List<int> bytes) {
    innerField.writeBytes(bytes);
  }

  @override
  void zeroClear() {
    innerField.zeroClear();
  }
}

