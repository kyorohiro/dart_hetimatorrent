library hetimatorrent.message.piece;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'torrentmessage.dart';


class MessagePiece extends TorrentMessage {

  int _mIndex = 0;
  int _mBegin = 0;
  List<int> _mContent = [];

  int get index => _mIndex; 
  int get begin => _mBegin;
  List<int> get content => new List.from(_mContent);

  MessagePiece._empty() : super(TorrentMessage.SIGN_PIECE) {
  }

  MessagePiece(int index, int begin, List<int> content) : super(TorrentMessage.SIGN_PIECE) {
    this._mIndex = index;
    this._mBegin = begin;
    this._mContent.addAll(content);
  }

  static Future<MessagePiece> decode(EasyParser parser) {
    Completer c = new Completer();
    MessagePiece message = new MessagePiece._empty();
    int messageLength = 0;
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      if(size < 9) {
        throw {};
      }
      messageLength = size;
      return parser.readByte();
    }).then((int v) {
      if(v != TorrentMessage.SIGN_PIECE) {
        throw {};
      }
      return parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
    }).then((int index) {
      message._mIndex = index;
      return parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
    }).then((int begin) {
      message._mBegin = begin;
      return parser.nextBuffer(messageLength-9);
    }).then((List<int> buffer) {
      message._mContent.addAll(buffer);
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
      builder.appendIntList(ByteOrder.parseIntByte(1+4*2+_mContent.length, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      builder.appendIntList(ByteOrder.parseIntByte(_mIndex, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendIntList(ByteOrder.parseIntByte(_mBegin, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendIntList(_mContent);
      return builder.toList();
    });
  }

  String toString() {
    return "${TorrentMessage.toText(id)}: ${_mIndex} ${_mBegin} contLen=${_mContent.length}";
  }
}
