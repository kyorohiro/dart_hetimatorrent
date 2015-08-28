library hetimatorrent.message.choke;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageChoke extends TorrentMessage {
  static const int CHOKE_LENGTH = 1;

  TMessageChoke() : super(TorrentMessage.SIGN_CHOKE) {
  }

  static Future<TMessageChoke> decode(EasyParser parser) {
    Completer c = new Completer();
    TMessageChoke message = new TMessageChoke();
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      if(size != CHOKE_LENGTH) {
        throw {};
      }
      return parser.readByte();
    }).then((int v) {
      if(v != TorrentMessage.SIGN_CHOKE) {
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
      builder.appendIntList(ByteOrder.parseIntByte(CHOKE_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      return builder.toList();
    });
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
