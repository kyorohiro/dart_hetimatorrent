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
  static const int ID_CONNECTED = 1001;
  static const int ID_ACCEPT = 1002;
  static const int ID_SET_PIECE = 1003;
  static const int ID_SET_PIECE_ALL = 1004;
  static const int ID_STARTED_CLIENT = 1005;
  static const int ID_STOPPED_CLIENT = 1006;
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
