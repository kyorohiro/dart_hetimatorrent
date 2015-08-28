library hetimatorrent.messagenull;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'torrentmessage.dart';

class TMessageNull extends TorrentMessage {
  List<int> _mMessageContent = [];

  List<int> get messageContent => new List.from(_mMessageContent);

  TMessageNull._empty(int id) : super(id) {}
  TMessageNull(int id, List<int> cont) : super(id) {
    _mMessageContent.addAll(cont);
  }

  static Future<TMessageNull> decode(EasyParser parser, {int maxOfMessageSize:2*1024*1024}) {
    Completer c = new Completer();
    TMessageNull message = null;
    int messageLength = 0;



    parser.push();
    parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN).then((int size) {
      messageLength = size;
      if(size >= maxOfMessageSize) {
        throw "";
      }
      if (size == 0) {
        return TorrentMessage.DUMMY_SIGN_KEEPALIVE;
      } else {
        return parser.readByte();
      }
    }).then((int v) {
      message = new TMessageNull._empty(v);
      if (messageLength > 0) {
        messageLength -= 1;
      }
      return parser.nextBuffer(messageLength);
    }).then((List<int> v) {
      print("##size, length= ${messageLength} ${v.length}");
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

  String toString() {
    return "${TorrentMessage.toText(id)}:";
  }
  
}
