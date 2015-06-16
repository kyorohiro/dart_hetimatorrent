library hetimatorrent.message.handshake;

import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'trackerresponse.dart';
import 'trackerurl.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../file/torrentfile.dart';

class MessageHandshake {
  static final List<int> RESERVED = new List.from([0, 0, 0, 0, 0, 0, 0, 0], growable:false);
  static final List<int> EMPTY = [0, 0, 0, 0, 0, 0, 0, 0];
  static final List<int> ProtocolId = new List.from(UTF8.encode("BitTorrent protocol"), growable: false); //19byte
  List<int> mProtocolId = new List.from(UTF8.encode("BitTorrent protocol"), growable: false); //19byte
  List<int> mInfoHash = [0, 0, 0, 0, 0, 0, 0, 0]; //20byte
  List<int> mPeerID = [0, 0, 0, 0, 0, 0, 0, 0]; //20byte
  List<int> mReserved = [0, 0, 0, 0, 0, 0, 0, 0]; //8byte

  static Future<MessageHandshake> decode(EasyParser parser) {}
}
