library hetimatorrent.message.notinterested;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageNotInterested extends TorrentMessage {
  static const int NOTINTERESTED_LENGTH = 1;

  TMessageNotInterested() : super(TorrentMessage.SIGN_NOTINTERESTED) {}

  static Future<TMessageNotInterested> decode(EasyParser parser, {List<int> buffer: null}) async {
    List<int> outLength = [0];
    TMessageNotInterested message = new TMessageNotInterested();
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
      if (size != NOTINTERESTED_LENGTH) {
        throw {};
      }
      int v = await parser.readByte(buffer: buffer, outLength: outLength);
      if (v != TorrentMessage.SIGN_NOTINTERESTED) {
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
    builder.appendIntList(ByteOrder.parseIntByte(NOTINTERESTED_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
