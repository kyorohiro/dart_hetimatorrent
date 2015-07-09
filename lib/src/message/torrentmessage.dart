library hetimatorrent.message.torentmessage;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

//
//

import 'messagehandshake.dart';
import 'messagebitfield.dart';
import 'messagecancel.dart';
import 'messagechoke.dart';
import 'messageunchoke.dart';
import 'messagehave.dart';
import 'messageinterested.dart';
import 'messagekeepalive.dart';
import 'messagenotinterested.dart';
import 'messagenull.dart';
import 'messageport.dart';
import 'messagerequest.dart';
import 'messagepiece.dart';

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

  static Future<TorrentMessage> parseHandshake(EasyParser parser, [int maxOfMessageSize = 256 * 1024]) {
    parser.push();
    return new Future(() {
      return MessageHandshake.decode(parser);
    }).catchError((e) {
      parser.back();
      throw e;
    }).whenComplete(() {
      parser.pop();
    });    
  }

  static  Future<TorrentMessage> parseBasic(EasyParser parser, [int maxOfMessageSize = 256 * 1024]) {
    parser.push();
        
    return new Future(() {
      return MessageNull.decode(parser).then((MessageNull nullMessage) {
        parser.back();
        switch (nullMessage._id) {
          case TorrentMessage.SIGN_BITFIELD:
            return MessageBitfield.decode(parser);
          case TorrentMessage.SIGN_CANCEL:
            return MessageCancel.decode(parser);
          case TorrentMessage.SIGN_CHOKE:
            return MessageChoke.decode(parser);
          case TorrentMessage.SIGN_HAVE:
            return MessageHave.decode(parser);
          case TorrentMessage.SIGN_INTERESTED:
            return MessageInterested.decode(parser);
          case TorrentMessage.SIGN_NOTINTERESTED:
            return MessageNotInterested.decode(parser);
          case TorrentMessage.SIGN_PIECE:
            return MessagePiece.decode(parser);
          case TorrentMessage.SIGN_PORT:
            return MessagePort.decode(parser);
          case TorrentMessage.SIGN_REQUEST:
            return MessageRequest.decode(parser);
          case TorrentMessage.SIGN_UNCHOKE:
            return MessageUnchoke.decode(parser);
          default:
            if(nullMessage.messageContent.length == 0) {
              return MessageKeepAlive.decode(parser);
            } else {
              return MessageNull.decode(parser);
            }
        }
      });
    }).catchError((e) {
      parser.back();
      throw e;
    }).whenComplete(() {
      parser.buffer.clearInnerBuffer(parser.getInedx());
      parser.pop();
    });
  }
  
  static String toText(int id) {
    switch(id) {
      case  DUMMY_SIGN_SHAKEHAND:
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
