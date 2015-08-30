library hetimatorrent.message.request;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageRequest extends TorrentMessage {
  static const int REQUEST_LENGTH = 1 + 4 * 3;
  int _mIndex = 0;
  int _mBegin = 0;
  int _mLength = 0;

  int get index => _mIndex;
  int get begin => _mBegin;
  int get length => _mLength;

  TMessageRequest._empty() : super(TorrentMessage.SIGN_REQUEST) {}

  TMessageRequest(int index, int begin, int length) : super(TorrentMessage.SIGN_REQUEST) {
    this._mIndex = index;
    this._mBegin = begin;
    this._mLength = length;
  }

  static Future<TMessageRequest> decode(EasyParser parser) async {
    TMessageRequest message = new TMessageRequest._empty();
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      if (size != REQUEST_LENGTH) {
        throw {};
      }
      int id = await parser.readByte();
      if (id != TorrentMessage.SIGN_REQUEST) {
        throw {};
      }
      message._mIndex = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      message._mBegin = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      message._mLength = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
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
    builder.appendIntList(ByteOrder.parseIntByte(REQUEST_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    builder.appendIntList(ByteOrder.parseIntByte(_mIndex, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendIntList(ByteOrder.parseIntByte(_mBegin, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendIntList(ByteOrder.parseIntByte(_mLength, ByteOrder.BYTEORDER_BIG_ENDIAN));
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}: ${_mIndex}  ${_mBegin}  ${_mLength}";
  }
}
