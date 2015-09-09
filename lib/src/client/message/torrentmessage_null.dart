library hetimatorrent.messagenull;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageNull extends TorrentMessage {
  List<int> _mMessageContent = [];

  List<int> get messageContent => new List.from(_mMessageContent);

  TMessageNull._empty(int id) : super(id) {}
  TMessageNull(int id, List<int> cont) : super(id) {
    _mMessageContent.addAll(cont);
  }

  static Future<TMessageNull> decode(EasyParser parser, {int maxOfMessageSize: 2 * 1024 * 1024}) async {
    parser.push();
    try {
      int messageLength = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      if (messageLength >= maxOfMessageSize) {
        throw "";
      }
      int vv = 0;
      if (messageLength == 0) {
        vv = TorrentMessage.DUMMY_SIGN_KEEPALIVE;
      } else {
        vv = await parser.readByte();
      }

      TMessageNull message = new TMessageNull._empty(vv);
      if (messageLength > 0) {
        messageLength -= 1;
      }
      List<int> v = await parser.nextBuffer(messageLength);
      //print("##size, length= ${messageLength} ${v.length}");
      message._mMessageContent.addAll(v);
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
    if (id == TorrentMessage.DUMMY_SIGN_KEEPALIVE) {
      builder.appendIntList(ByteOrder.parseIntByte(0, ByteOrder.BYTEORDER_BIG_ENDIAN));
    } else {
      builder.appendIntList(ByteOrder.parseIntByte(1 + _mMessageContent.length, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      builder.appendIntList(_mMessageContent);
    }
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
}
