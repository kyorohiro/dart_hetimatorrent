library hetimatorrent.messagenull;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'torrentmessage.dart';

class MessageNull extends TorrentMessage {
  List<int> _mMessageContent = [];

  List<int> get messageContent => new List.from(_mMessageContent);

  MessageNull._empty(int id) : super(id) {}
  MessageNull(int id, List<int> cont) : super(id) {
    _mMessageContent.addAll(cont);
  }

  static Future<MessageNull> decode(EasyParser parser) {
    Completer c = new Completer();
    MessageNull message = null;
    int messageLength = 0;
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      messageLength = size;
      if (size == 0) {
        return TorrentMessage.DUMMY_SIGN_KEEPALIVE;
      } else {
        return parser.readByte();
      }
    }).then((int v) {
      message = new MessageNull._empty(v);
      if (messageLength > 0) {
        messageLength -= 1;
      }
      return parser.nextBuffer(messageLength);
    }).then((List<int> v) {
      message._mMessageContent.addAll(v);
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
      if (id == TorrentMessage.DUMMY_SIGN_KEEPALIVE) {
        builder.appendIntList(ByteOrder.parseIntByte(0, ByteOrder.BYTEORDER_BIG_ENDIAN));
      } else {
        builder.appendIntList(ByteOrder.parseIntByte(1 + _mMessageContent.length, ByteOrder.BYTEORDER_BIG_ENDIAN));
        builder.appendByte(id);
        builder.appendIntList(_mMessageContent);
      }
      return builder.toList();
    });
  }
}
