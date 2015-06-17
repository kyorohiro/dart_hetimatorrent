library hetimatorrent.message.torentmessage;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

class TorrentMessage {
  static const int DUMMY_SIGN_SHAKEHAND = 1001;
  static const int DUMMY_SIGN_KEEPALIVE = 1002;
  static const int DUMMY_SIGN_NULL = 1003;
  static const int SIGN_CHOKE = 0;
  static const int SIGN_UNCHOKE = 1;
  static const int SIGN_INTERESTED = 2;
  static const int SIGN_NOTINTERESTED = 3;
  static const int SIGN_HAVE = 4;
  static const int SIGN_BITFIELD = 5;
  static const int SIGN_REQUEST = 6;
  static const int SIGN_PIECE = 7;
  static const int SIGN_CANCEL = 8;
  static const int SIGN_PORT = 9;// For MDHT 

  static final int SIGN_LENGTH = 1; //1 byte
  int _id = 0;
  int get id => _id;

  TorrentMessage(int id) {
    _id = id;
  }

}
