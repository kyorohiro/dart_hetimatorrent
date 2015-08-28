library hetimatorrent.message.port;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessagePort extends TorrentMessage {
  static const int PORT_LENGTH = 1+2;
  int _mPort = 0;
  int get port => _mPort; 

  TMessagePort._empty() : super(TorrentMessage.SIGN_PORT) {
  }

  TMessagePort(int port) : super(TorrentMessage.SIGN_PORT) {
    this._mPort = port;
  }

  static Future<TMessagePort> decode(EasyParser parser) {
    Completer c = new Completer();
    TMessagePort message = new TMessagePort._empty();
    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      if(size != PORT_LENGTH) {
        throw {};
      }
      return parser.readByte();
    }).then((int v) {
      if(v != TorrentMessage.SIGN_PORT) {
        throw {};
      }
      return parser.readShort(ByteOrder.BYTEORDER_BIG_ENDIAN);
    }).then((int index) {
      message._mPort = index;
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
      builder.appendIntList(ByteOrder.parseIntByte(PORT_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
      builder.appendByte(id);
      builder.appendIntList(ByteOrder.parseShortByte(_mPort, ByteOrder.BYTEORDER_BIG_ENDIAN));
      return builder.toList();
    });
  }

  String toString() {
    return "${TorrentMessage.toText(id)}: ${_mPort}";
  }
}
