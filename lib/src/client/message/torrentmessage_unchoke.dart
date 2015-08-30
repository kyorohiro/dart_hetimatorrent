library hetimatorrent.message.unchoke;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageUnchoke extends TorrentMessage {
  static const int UNCHOKE_LENGTH = 1;

  TMessageUnchoke() : super(TorrentMessage.SIGN_UNCHOKE) {}

  static Future<TMessageUnchoke> decode(EasyParser parser) async {
    TMessageUnchoke message = new TMessageUnchoke();
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      if (size != UNCHOKE_LENGTH) {
        throw {};
      }
      int id = await parser.readByte();
      if (id != TorrentMessage.SIGN_UNCHOKE) {
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
    builder.appendIntList(ByteOrder.parseIntByte(UNCHOKE_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
