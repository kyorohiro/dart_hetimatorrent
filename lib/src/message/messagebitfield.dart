library hetimatorrent.message.handshake;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'torrentmessage.dart';

class MessageBitfield extends TorrentMessage {
  static final List<int> RESERVED = new List.from([0, 0, 0, 0, 0, 0, 0, 0], growable: false);

  List<int> _mBitfield = []; // *

  MessageBitfield._empty() : super(TorrentMessage.SIGN_BITFIELD) {
    _mBitfield.clear();
  }

  MessageBitfield(List<int> bitfield) : super(TorrentMessage.SIGN_BITFIELD) {
    _mBitfield.clear();
    _mBitfield.addAll(bitfield);
  }

  static Future<MessageBitfield> decode(EasyParser parser) {
    Completer c = new Completer();
    MessageBitfield message = new MessageBitfield._empty();
    int messageSize = 0;

    parser.push();
    parser.readByte().then((int size) {
      messageSize = size;
      return parser.readByte();
    }).then((int id) {
      if (id != TorrentMessage.SIGN_BITFIELD) {
        throw {};
      }
      return parser.nextBuffer(messageSize - 1);
    }).then((List<int> field) {
      message._mBitfield.addAll(field);
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
      builder.appendIntList(ByteOrder.parseIntByte(TorrentMessage.SIGN_LENGTH + _mBitfield.length, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      builder.appendIntList(_mBitfield);
      return builder.toList();
    });
  }
}
