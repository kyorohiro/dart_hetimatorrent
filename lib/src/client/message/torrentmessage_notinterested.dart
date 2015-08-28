library hetimatorrent.message.notinterested;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageNotInterested extends TorrentMessage {
  static const int NOTINTERESTED_LENGTH = 1;

  TMessageNotInterested() : super(TorrentMessage.SIGN_NOTINTERESTED) {
  }

  static Future<TMessageNotInterested> decode(EasyParser parser) {
    Completer c = new Completer();
    TMessageNotInterested message = new TMessageNotInterested();
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      if(size != NOTINTERESTED_LENGTH) {
        throw {};
      }
      return parser.readByte();
    }).then((int v) {
      if(v != TorrentMessage.SIGN_NOTINTERESTED) {
        throw {};
      }
      parser.pop();
      c.complete(message);
    }).catchError((e) {
      parser.back();
      parser.pop();
      c.completeError(e);
    });
    return c.future;
  }

  Future<List<int>> encode() {
    return new Future(() {
      ArrayBuilder builder = new ArrayBuilder();
      builder.appendIntList(ByteOrder.parseIntByte(NOTINTERESTED_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      return builder.toList();
    });
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
