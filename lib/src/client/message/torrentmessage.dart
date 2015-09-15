library hetimatorrent.message.torentmessage;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';

import 'torrentmessage_handshake.dart';
import 'torrentmessage_bitfield.dart';
import 'torrentmessage_cancel.dart';
import 'torrentmessage_choke.dart';
import 'torrentmessage_unchoke.dart';
import 'torrentmessage_have.dart';
import 'torrentmessage_interested.dart';
import 'torrentmessage_keepalive.dart';
import 'torrentmessage_notinterested.dart';
import 'torrentmessage_null.dart';
import 'torrentmessage_port.dart';
import 'torrentmessage_request.dart';
import 'torrentmessage_piece.dart';

class TorrentMessage {
  static const int DUMMY_SIGN_SHAKEHAND = 501;
  static const int DUMMY_SIGN_KEEPALIVE = 502;
  static const int DUMMY_SIGN_NULL = 503;
  static const int SIGN_CHOKE = 0;
  static const int SIGN_UNCHOKE = 1;
  static const int SIGN_INTERESTED = 2;
  static const int SIGN_NOTINTERESTED = 3;
  static const int SIGN_HAVE = 4;
  static const int SIGN_BITFIELD = 5;
  static const int SIGN_REQUEST = 6;
  static const int SIGN_PIECE = 7;
  static const int SIGN_CANCEL = 8;
  static const int SIGN_PORT = 9; // For MDHT
  static final int SIGN_LENGTH = 1; //1 byte
  int _id = 0;
  int get id => _id;

  TorrentMessage(int id) {
    _id = id;
  }

  Future<List<int>> encode() async {
    return [0];
  }

  static Future<TorrentMessage> parseHandshake(EasyParser parser, [int maxOfMessageSize = 256 * 1024]) async {
    parser.push();
    try {
      TMessageHandshake message = await TMessageHandshake.decode(parser);
      parser.pop();
      return message;
    } catch (e) {
      parser.back();
      parser.pop();
      throw e;
    }
  }

  static Future<TorrentMessage> parseBasic(EasyParser parser, {int maxOfMessageSize: 3 * 16 * 1024, List<int> buffer}) async {
    parser.push();
    List<int> outLength = [0];
    try {
      int id = 0;
      int messageLength = await parser.readInt(ByteOrder.BYTEORDER_BIG_ENDIAN, buffer: buffer, outLength: outLength);
      if (messageLength >= maxOfMessageSize) {
        throw "";
      }
      if (messageLength == 0) {
        id = TorrentMessage.DUMMY_SIGN_KEEPALIVE;
      } else {
        id = await parser.readByte(buffer: buffer, outLength: outLength);
      }
      parser.back();
      switch (id) {
        case TorrentMessage.SIGN_BITFIELD:
          return TMessageBitfield.decode(parser, buffer: buffer);
        case TorrentMessage.SIGN_CANCEL:
          return TMessageCancel.decode(parser, buffer:buffer);
        case TorrentMessage.SIGN_CHOKE:
          return TMessageChoke.decode(parser);
        case TorrentMessage.SIGN_HAVE:
          return TMessageHave.decode(parser);
        case TorrentMessage.SIGN_INTERESTED:
          return TMessageInterested.decode(parser);
        case TorrentMessage.SIGN_NOTINTERESTED:
          return TMessageNotInterested.decode(parser);
        case TorrentMessage.SIGN_PIECE:
          return TMessagePiece.decode(parser);
        case TorrentMessage.SIGN_PORT:
          return TMessagePort.decode(parser);
        case TorrentMessage.SIGN_REQUEST:
          return TMessageRequest.decode(parser);
        case TorrentMessage.SIGN_UNCHOKE:
          return TMessageUnchoke.decode(parser);
        case TorrentMessage.DUMMY_SIGN_KEEPALIVE:
          return TMessageKeepAlive.decode(parser);
        default:
          return TMessageNull.decode(parser);
      }
    } catch (e) {
      parser.back();
      throw e;
    } finally {
      //parser.buffer.clearInnerBuffer(parser.getInedx());
      parser.pop();
    }
  }

  static String toText(int id) {
    switch (id) {
      case DUMMY_SIGN_SHAKEHAND:
        return "shakehand(${id})";
      case DUMMY_SIGN_KEEPALIVE:
        return "keepalive(${id})";
      case DUMMY_SIGN_NULL:
        return "null(${id})";
      case SIGN_CHOKE:
        return "choke(${id})";
      case SIGN_UNCHOKE:
        return "unchoke(${id})";
      case SIGN_INTERESTED:
        return "interested(${id})";
      case SIGN_NOTINTERESTED:
        return "notinterested(${id})";
      case SIGN_HAVE:
        return "have(${id})";
      case SIGN_BITFIELD:
        return "bitfield(${id})";
      case SIGN_REQUEST:
        return "request(${id})";
      case SIGN_PIECE:
        return "piece(${id})";
      case SIGN_CANCEL:
        return "cancel(${id})";
      case SIGN_PORT:
        return "port(${id})";
      default:
        return "other(${id})";
    }
  }
}
