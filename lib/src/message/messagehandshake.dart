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
  static final List<int> RESERVED = new List.from([0, 0, 0, 0, 0, 0, 0, 0], growable: false);
  static final List<int> EMPTY = [0, 0, 0, 0, 0, 0, 0, 0];
  static final List<int> ProtocolId = new List.from(UTF8.encode("BitTorrent protocol"), growable: false); //19byte
  List<int> mProtocolId = []; //19byte
  List<int> mInfoHash = []; //20byte
  List<int> mPeerID = []; //20byte
  List<int> mReserved = [0, 0, 0, 0, 0, 0, 0, 0]; //8byte

  List<int> get infoHash => new List.from(mInfoHash, growable: false);

  static Future<MessageHandshake> decode(EasyParser parser) {
    Completer c = new Completer();
    MessageHandshake mesHandshake = new MessageHandshake();
    parser.readByte().then((int size) {
      if (!(0 <= size && size <= 256)) {
        throw {};
      }
      return parser.nextBuffer(size);
    }).then((List<int> id) {
      mesHandshake.mProtocolId.clear();
      mesHandshake.mProtocolId.addAll(id);
      return parser.nextBuffer(8);
    }).then((List<int> reserved) {
      mesHandshake.mReserved.clear();
      mesHandshake.mReserved.addAll(reserved);
      return parser.nextBuffer(20);
    }).then((List<int> infoHash) {
      mesHandshake.mInfoHash.clear();
      mesHandshake.mInfoHash.addAll(infoHash);
      return parser.nextBuffer(20);
    }).then((List<int> peerId) {
      mesHandshake.mPeerID.clear();
      mesHandshake.mPeerID.addAll(peerId);
      c.complete(mesHandshake);
    }).catchError((e) {
      c.completeError(e);
    });
    return c.future;
  }
}
