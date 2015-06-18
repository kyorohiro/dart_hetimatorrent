library hetimatorrent.message.request;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'torrentmessage.dart';

class MessageRequest extends TorrentMessage {

  static const int REQUEST_LENGTH = 1+4*3;
  int _mIndex = 0;
  int _mBegin = 0;
  int _mLength = 0;

  int get index => _mIndex; 
  int get begin => _mBegin;
  int get length => _mLength;

  MessageRequest._empty() : super(TorrentMessage.SIGN_REQUEST) {
  }

  MessageRequest(int index, int begin, int length) : super(TorrentMessage.SIGN_REQUEST) {
    this._mIndex = index;
    this._mBegin = begin;
    this._mLength= length;
  }

  static Future<MessageRequest> decode(EasyParser parser) {
    Completer c = new Completer();
    MessageRequest message = new MessageRequest._empty();
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      if(size != REQUEST_LENGTH) {
        throw {};
      }
      return parser.readByte();
    }).then((int v) {
      if(v != TorrentMessage.SIGN_REQUEST) {
        throw {};
      }
      return parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
    }).then((int index) {
      message._mIndex = index;
      return parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
    }).then((int begin) {
      message._mBegin = begin;
      return parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
    }).then((int length) {
      message._mLength = length;
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
      builder.appendIntList(ByteOrder.parseIntByte(REQUEST_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      builder.appendIntList(ByteOrder.parseIntByte(_mIndex, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendIntList(ByteOrder.parseIntByte(_mBegin, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendIntList(ByteOrder.parseIntByte(_mLength, ByteOrder.BYTEORDER_BIG_ENDIAN));
      return builder.toList();
    });
  }
}
