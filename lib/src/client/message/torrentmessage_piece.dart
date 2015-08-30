library hetimatorrent.message.piece;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessagePiece extends TorrentMessage {
  int _mIndex = 0;
  int _mBegin = 0;
  List<int> _mContent = [];

  int get index => _mIndex;
  int get begin => _mBegin;
  List<int> get content => new List.from(_mContent);

  TMessagePiece._empty() : super(TorrentMessage.SIGN_PIECE) {}

  TMessagePiece(int index, int begin, List<int> content) : super(TorrentMessage.SIGN_PIECE) {
    this._mIndex = index;
    this._mBegin = begin;
    this._mContent.addAll(content);
  }

  static Future<TMessagePiece> decode(EasyParser parser) async {
    TMessagePiece message = new TMessagePiece._empty();
    parser.push();
    try {
      int messageLength = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      if (messageLength < 9) {
        throw {};
      }
      int vv = await parser.readByte();
      if (vv != TorrentMessage.SIGN_PIECE) {
        throw {};
      }
      message._mIndex = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      message._mBegin = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      List<int> buffer = await parser.nextBuffer(messageLength - 9);
      message._mContent.addAll(buffer);
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
    builder.appendIntList(ByteOrder.parseIntByte(1 + 4 * 2 + _mContent.length, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    builder.appendIntList(ByteOrder.parseIntByte(_mIndex, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendIntList(ByteOrder.parseIntByte(_mBegin, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendIntList(_mContent);
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}: ${_mIndex} ${_mBegin} contLen=${_mContent.length}";
  }
}
