library hetimatorrent.message.keepalive;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'torrentmessage.dart';

class MessageKeepAlive extends TorrentMessage {
  static const int HAVE_LENGTH = 0;
  MessageKeepAlive() : super(TorrentMessage.DUMMY_SIGN_KEEPALIVE) {
  }

  static Future<MessageKeepAlive> decode(EasyParser parser) {
    Completer c = new Completer();
    MessageKeepAlive message = new MessageKeepAlive();
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      if(size != 0) {
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
      builder.appendIntList(ByteOrder.parseIntByte(0, ByteOrder.BYTEORDER_BIG_ENDIAN));
      return builder.toList();
    });
  }
}
