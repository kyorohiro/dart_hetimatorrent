library hetimatorrent.message.port;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessagePort extends TorrentMessage {
  static const int PORT_LENGTH = 1 + 2;
  int _mPort = 0;
  int get port => _mPort;

  TMessagePort._empty() : super(TorrentMessage.SIGN_PORT) {}

  TMessagePort(int port) : super(TorrentMessage.SIGN_PORT) {
    this._mPort = port;
  }

  static Future<TMessagePort> decode(EasyParser parser) async {
    TMessagePort message = new TMessagePort._empty();
    parser.push();
    try {
      int size = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN);
      if (size != PORT_LENGTH) {
        throw {};
      }
      int id = await parser.readByte();
      if (id != TorrentMessage.SIGN_PORT) {
        throw {};
      }
      message._mPort = await parser.readShort(ByteOrder.BYTEORDER_BIG_ENDIAN);
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
    builder.appendIntList(ByteOrder.parseIntByte(PORT_LENGTH, ByteOrder.BYTEORDER_BIG_ENDIAN));
    builder.appendByte(id);
    builder.appendIntList(ByteOrder.parseShortByte(_mPort, ByteOrder.BYTEORDER_BIG_ENDIAN));
    return builder.toList();
  }

  String toString() {
    return "${TorrentMessage.toText(id)}: ${_mPort}";
  }
}
