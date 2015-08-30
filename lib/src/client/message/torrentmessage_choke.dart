library hetimatorrent.message.choke;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageChoke extends TorrentMessage {
  static const int CHOKE_LENGTH = 1;

  TMessageChoke() : super(TorrentMessage.SIGN_CHOKE) {}

  static Future<TMessageChoke> decode(EasyParser parser) async {
    TMessageChoke message = new TMessageChoke();
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      if (size != CHOKE_LENGTH) {
        throw {};
      }
      int v = await parser.readByte();
      if (v != TorrentMessage.SIGN_CHOKE) {
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
    builder.appendIntList(ByteOrder.parseIntByte(CHOKE_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
