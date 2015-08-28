library hetimatorrent.message.bitfield;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageBitfield extends TorrentMessage {
  static final List<int> RESERVED = new List.from([0, 0, 0, 0, 0, 0, 0, 0], growable: false);

  List<int> _mBitfield = []; // *

  List<int> get bitfield => new List.from(_mBitfield, growable: false);

  TMessageBitfield._empty() : super(TorrentMessage.SIGN_BITFIELD) {
    _mBitfield.clear();
  }

  TMessageBitfield(List<int> bitfield) : super(TorrentMessage.SIGN_BITFIELD) {
    _mBitfield.clear();
    _mBitfield.addAll(bitfield);
  }

  static Future<TMessageBitfield> decode(EasyParser parser) {
    Completer c = new Completer();
    TMessageBitfield message = new TMessageBitfield._empty();
    int messageSize = 0;

    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
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

  String toString() {
    return "${TorrentMessage.toText(id)}:${bitfield}";
  }
}
