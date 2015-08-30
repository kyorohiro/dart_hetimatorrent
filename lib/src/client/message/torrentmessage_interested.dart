library hetimatorrent.message.interested;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageInterested extends TorrentMessage {
  static const int INTERESTED_LENGTH = 1;

  TMessageInterested() : super(TorrentMessage.SIGN_INTERESTED) {}

  static Future<TMessageInterested> decode(EasyParser parser) async {
    TMessageInterested message = new TMessageInterested();
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      if (size != INTERESTED_LENGTH) {
        throw {};
      }
      int v = await parser.readByte();
      if (v != TorrentMessage.SIGN_INTERESTED) {
        throw {};
      }
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
    builder.appendIntList(ByteOrder.parseIntByte(INTERESTED_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
