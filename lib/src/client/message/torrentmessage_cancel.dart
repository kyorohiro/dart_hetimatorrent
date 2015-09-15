library hetimatorrent.message.cancel;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageCancel extends TorrentMessage {
  static final List<int> RESERVED = new List.from([0, 0, 0, 0, 0, 0, 0, 0], growable: false);

  static const int CANCEL_LENGTH = 1 + 4 * 3;
  int _mIndex = 0;
  int _mBegin = 0;
  int _mLength = 0;

  int get index => _mIndex;
  int get begin => _mBegin;
  int get length => _mLength;

  TMessageCancel._empty() : super(TorrentMessage.SIGN_CANCEL) {}

  TMessageCancel(int index, int begin, int length) : super(TorrentMessage.SIGN_CANCEL) {
    this._mIndex = index;
    this._mBegin = begin;
    this._mLength = length;
  }

  static Future<TMessageCancel> decode(EasyParser parser, {List<int> buffer: null}) async {
    List<int> outLength = [0];
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
      if (size != CANCEL_LENGTH) {
        throw {};
      }
      int v = await parser.readByte(buffer: buffer, outLength: outLength);
      if (v != TorrentMessage.SIGN_CANCEL) {
        throw {};
      }
      TMessageCancel message = new TMessageCancel._empty();
      message._mIndex = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
      message._mBegin = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
      message._mLength = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
      parser.pop();
      return message;
    } catch (e) {
      parser.back();
      parser.pop();
      throw e;
    }
  }

  Future<List<int>> encode() async {
    ArrayBuilder builder = new ArrayBuilder();
    builder.appendIntList(ByteOrder.parseIntByte(CANCEL_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    builder.appendIntList(ByteOrder.parseIntByte(_mIndex, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendIntList(ByteOrder.parseIntByte(_mBegin, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendIntList(ByteOrder.parseIntByte(_mLength, ByteOrder.BYTEORDER_BIG_ENDIAN));
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:${_mIndex} ${_mBegin} ${_mLength}";
  }
}
