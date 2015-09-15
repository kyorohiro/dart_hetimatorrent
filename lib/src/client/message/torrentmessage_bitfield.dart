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

  static Future<TMessageBitfield> decode(EasyParser parser, {List<int> buffer:null}) async {
    List<int> outLength = [0];
    parser.push();
    try {
      int messageSize = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer:buffer, outLength:outLength);
      int id = await parser.readByte(buffer:buffer, outLength:outLength);
      if (id != TorrentMessage.SIGN_BITFIELD) {
        throw {};
      }
      List<int> field = await parser.nextBuffer(messageSize - 1, buffer:buffer, outLength:outLength);
      if(outLength[0] != messageSize - 1) {
        throw {};
      }
      TMessageBitfield message = new TMessageBitfield._empty();
      message._mBitfield.addAll(field);
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
    builder.appendIntList(ByteOrder.parseIntByte(TorrentMessage.SIGN_LENGTH + _mBitfield.length, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    builder.appendIntList(_mBitfield);
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}:${bitfield}";
  }
}
