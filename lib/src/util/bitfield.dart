library hetimatorrent.util.bitfield;

import 'dart:core';
import 'dart:typed_data';

abstract class BitfieldInter {
  static final List<int> BIT = [0xFF, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE];
  List<int> get value;
  List<int> get rawValue;
  void writeBytes(List<int> bytes);
  void oneClear();
  void zeroClear();
  int lengthPerBit();
  int lengthPerByte();
  List<int> getBinary();
  bool isAllOff();
  bool isAllOn();
  bool getIsOn(int number);
  void setIsOn(int number, bool on);
  bool isAllOnPerByte(int number);
  bool isAllOffPerByte(int number);
  void update() {}
}

class Bitfield extends BitfieldInter {
  static final List<int> BIT = [0xFF, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE];

  int _bitSize = 0;
  List<int> _bitfieldData = null;

  List<int> get value => new Uint8List.fromList(_bitfieldData);
  List<int> get rawValue => _bitfieldData;

  static int calcbitSize(int pieceSize, {pieceLength: 20}) {
    int ret = pieceSize ~/ pieceLength;
    if (pieceSize % pieceLength != 0) {
      print("wearning todo: --break bitfield");
      ret + 1;
    }
    return ret;
  }

  Bitfield(int bitSize, {bool clearIsOne: true, seed: null}) {
    this._bitSize = bitSize;
    int byteSize = bitSize ~/ 8;
    if (bitSize % 8 != 0) {
      byteSize += 1;
    }
    _bitfieldData = new Uint8List(byteSize);
    if (clearIsOne) {
      oneClear();
    } else {
      zeroClear();
    }
  }

  static BitfieldInter relative(BitfieldInter ina, BitfieldInter inb, BitfieldInter out) {
    if (out == null) {
      int len = ina.lengthPerBit();
      out = new Bitfield(len);
    }
    int len = out.lengthPerByte();
    if (len > inb.lengthPerByte()) {
      len = inb.lengthPerByte();
    }
    out.value;
    for (int i = 0; i < out.lengthPerByte(); i++) {
      out.rawValue[i] = (0xFF & out.rawValue[i]);
    }
    for (int i = 0; i < len; i++) {
      out.rawValue[i] = (0xFF & ina.rawValue[i] & (~inb.rawValue[i]));
    }
    out.update();
    return out;
  }

  //
  // todo addtest
  void writeBytes(List<int> bytes) {
    _bitfieldData.setRange(0, bytes.length, bytes);
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

  int numOfOn(bool isOn) {
    int ret = 0;
    int len = lengthPerBit();
    for (int i = 0; i < len; i++) {
      if (getIsOn(i) == isOn) {
        ret++;
      }
    }
    return ret;
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

  bool operator [](int idx) => getIsOn(idx);
  void operator []=(int index, bool value) => setIsOn(index, value);

  bool getIsOn(int idx) {
    // 8 0, 7 1, 3 3 7 7
    if (_bitfieldData == null || idx ~/ 8 >= _bitfieldData.length) {
      return false;
    }
    if (((_bitfieldData[idx ~/ 8] >> (7 - idx % 8)) & 0x01) == 0x01) {
      return true;
    } else {
      return false;
    }
  }

  void setIsOn(int idx, bool on) {
    // 8 0, 7 1, 3 3 7 7
    if (_bitfieldData == null || idx ~/ 8 >= _bitfieldData.length || idx >= lengthPerBit()) {
      return;
    }

    int value = 0x01 << (7 - idx % 8);
    int v = _bitfieldData[idx ~/ 8];
    if (on) {
      _bitfieldData[idx ~/ 8] = v | value;
    } else {
      value = value ^ 0xFFFFFFFF;
      _bitfieldData[idx ~/ 8] = v & value;
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

  void update() {}
}


