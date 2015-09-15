library hetimatorrent.message.have;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageHave extends TorrentMessage {
  static const int HAVE_LENGTH = 1 + 4 * 1;
  int _mIndex = 0;
  int get index => _mIndex;

  TMessageHave._empty() : super(TorrentMessage.SIGN_HAVE) {}

  TMessageHave(int index) : super(TorrentMessage.SIGN_HAVE) {
    this._mIndex = index;
  }

  static Future<TMessageHave> decode(EasyParser parser, {List<int> buffer: null}) async {
    List<int> outLength = [0];
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
      if (size != HAVE_LENGTH) {
        throw {};
      }
      int v = await parser.readByte(buffer: buffer, outLength: outLength);
      if (v != TorrentMessage.SIGN_HAVE) {
        throw {};
      }
      TMessageHave message = new TMessageHave._empty();
      message._mIndex = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
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
    builder.appendIntList(ByteOrder.parseIntByte(HAVE_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    builder.appendIntList(ByteOrder.parseIntByte(_mIndex, ByteOrder.BYTEORDER_BIG_ENDIAN));
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}: ${_mIndex}";
  }
}
