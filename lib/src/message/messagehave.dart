library hetimatorrent.message.have;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'torrentmessage.dart';

class MessageHave extends TorrentMessage {
  static const int HAVE_LENGTH = 1+4*1;
  int _mIndex = 0;
  int get index => _mIndex; 

  MessageHave._empty() : super(TorrentMessage.SIGN_HAVE) {
  }

  MessageHave(int index) : super(TorrentMessage.SIGN_HAVE) {
    this._mIndex = index;
  }

  static Future<MessageHave> decode(EasyParser parser) {
    Completer c = new Completer();
    MessageHave message = new MessageHave._empty();
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      if(size != HAVE_LENGTH) {
        throw {};
      }
      return parser.readByte();
    }).then((int v) {
      if(v != TorrentMessage.SIGN_HAVE) {
        throw {};
      }
      return parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
    }).then((int index) {
      message._mIndex = index;
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
      builder.appendIntList(ByteOrder.parseIntByte(HAVE_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      builder.appendIntList(ByteOrder.parseIntByte(_mIndex, ByteOrder.BYTEORDER_BIG_ENDIAN));
      return builder.toList();
    });
  }
}
