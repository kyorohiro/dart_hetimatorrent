library hetimatorrent.message.unchoke;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class MessageUnchoke extends TorrentMessage {
  static const int UNCHOKE_LENGTH = 1;

  MessageUnchoke() : super(TorrentMessage.SIGN_UNCHOKE) {
  }

  static Future<MessageUnchoke> decode(EasyParser parser) {
    Completer c = new Completer();
    MessageUnchoke message = new MessageUnchoke();
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      if(size != UNCHOKE_LENGTH) {
        throw {};
      }
      return parser.readByte();
    }).then((int v) {
      if(v != TorrentMessage.SIGN_UNCHOKE) {
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
      builder.appendIntList(ByteOrder.parseIntByte(UNCHOKE_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      return builder.toList();
    });
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
