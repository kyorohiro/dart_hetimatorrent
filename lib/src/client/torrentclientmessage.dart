library hetimatorrent.torrent.client.message;

import 'dart:core';
import '../message/message.dart';

import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';



class TorrentClientMessage {
  TorrentMessage message;
  TorrentClientFront get front => _info.front;
  TorrentClientPeerInfo get info => _info;
  TorrentClientPeerInfo _info;

  TorrentClientMessage(TorrentClientPeerInfo info, TorrentMessage message) {
    this.message = message;
    this._info = info;
  }

  String toString() {
    return "signal:info:${info.id} ${info.ip} ${info.portAcceptable} message:${message.toString()}";
  }
}

class TorrentClientSignal {
  //
  static const ID_HANDSHAKED = 1;
  static const ID_CLOSE = 2;
  static const ID_PIECE_SEND = 3;
  static const ID_PIECE_RECEIVE = 4;
  static const REASON_OWN_CONNECTION = 2001;
  //
  static const int ID_CONNECTED = 1001;
  static const int ID_ACCEPT = 1002;
  static const int ID_SET_PIECE = 1003;
  static const int ID_SET_PIECE_ALL = 1004;
  static const int ID_STARTED_CLIENT = 1005;
  static const int ID_STOPPED_CLIENT = 1006;
  static const int ID_ADD_PEERINFO = 1007;
  
  int _id = 0;
  int _reason = 0;
  int get id => _id;
  int get reason => _reason;
  String _message = "";

  TorrentClientSignal(int id, int reason, String message) {
    _id = id;
    _reason = reason;
  }

  String toString() {
    return "${_message}";
  }
}

class TorrentClientSignalWithFront extends TorrentClientSignal {
  TorrentClientFront _front;
  TorrentClientFront get front=> _front;
  int _v = 0;
  int get v => _v;

  TorrentClientSignalWithFront(TorrentClientFront front, int id, int reason,String message,[int v=0]) : super(id, reason, message) {
    this._front = front;
    this._v = v;
  }

}


class TorrentClientSignalWithPeerInfo extends TorrentClientSignal {
  TorrentClientPeerInfo _info;
  TorrentClientPeerInfo get info => _info;

  TorrentClientSignalWithPeerInfo(TorrentClientPeerInfo info, int id, int reason, String message) : super(id, reason, message) {
    this._info = info;
  }

  String toString() {
    return "signal:info:${_info.id} ${_info.ip} ${_info.portAcceptable} signal:${_message}";
  }
}
