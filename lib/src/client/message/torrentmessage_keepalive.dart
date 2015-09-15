library hetimatorrent.message.keepalive;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'torrentmessage.dart';

class TMessageKeepAlive extends TorrentMessage {
  static const int HAVE_LENGTH = 0;
  TMessageKeepAlive() : super(TorrentMessage.DUMMY_SIGN_KEEPALIVE) {}

  static Future<TMessageKeepAlive> decode(EasyParser parser, {List<int> buffer: null}) async {
    List<int> outLength = [0];
    Completer c = new Completer();
    TMessageKeepAlive message = new TMessageKeepAlive();
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
      if (size != 0) {
        throw {};
      }
      parser.pop();
      return message;
    } catch (e) {
      parser.back();
      parser.pop();
      throw e;
    }
    return c.future;
  }

  Future<List<int>> encode() async {
    ArrayBuilder builder = new ArrayBuilder();
    builder.appendIntList(ByteOrder.parseIntByte(0, ByteOrder.BYTEORDER_BIG_ENDIAN));
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
