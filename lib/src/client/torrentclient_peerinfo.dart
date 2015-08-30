library hetimatorrent.torrent.client.peerinfo;

import 'dart:core';
import 'torrentclient_front.dart';

abstract class TorrentClientPeerInfo {
  static int nid = 0;
  int id = 0;

  String ip = "";
  int acceptablePort = 0;
  TorrentClientFront front = null;
  bool get isAcceptable => acceptablePort != 0;

  List<int> get peerId;
  int get speed;
  int get downloadedBytesFromMe;
  int get uploadedBytesToMe;
  int get chokedFromMe;
  int get chokedToMe;
  int get interestedToMe;
  int get interestedFromMe;
  bool get amI;
  bool get isClose;
  int get uploadSpeedFromUnchokeFromMe;
}

class TorrentClientPeerInfoEmpty extends TorrentClientPeerInfo {
  static int nid = 0;
  int id = 0;

  String ip = "";
  int acceptablePort = 0;
  TorrentClientFront front = null;
  bool get isAcceptable => acceptablePort != 0;

  TorrentClientPeerInfoEmpty() {}

  List<int> peerId = [];
  int speed = 0;
  int downloadedBytesFromMe = 0;
  int uploadedBytesToMe = 0;
  int chokedFromMe = TorrentClientFront.STATE_NONE;
  int chokedToMe = TorrentClientFront.STATE_NONE;
  int interestedToMe = TorrentClientFront.STATE_NONE;
  int interestedFromMe = TorrentClientFront.STATE_NONE;
  bool amI = false;
  bool isClose = true;
  int uploadSpeedFromUnchokeFromMe = 0;
}

class TorrentClientPeerInfoBasic extends TorrentClientPeerInfo {
  static int nid = 0;
  int id = 0;

  String ip = "";
  int acceptablePort = 0;
  TorrentClientFront front = null;
  bool get isAcceptable => acceptablePort != 0;

  TorrentClientPeerInfoBasic(String ip, int port) {
    this.id = ++nid;
    this.ip = ip;
    this.acceptablePort = port;
  }

  List<int> get peerId => (front == null ? [] : front.targetPeerId);
  int get speed => (front == null ? 0 : front.speed);
  int get downloadedBytesFromMe => (front == null ? 0 : front.downloadedBytesFromMe);
  int get uploadedBytesToMe => (front == null ? 0 : front.uploadedBytesToMe);
  int get chokedFromMe => (front == null ? TorrentClientFront.STATE_NONE: front.chokedFromMe);
  int get chokedToMe => (front == null ? TorrentClientFront.STATE_NONE: front.chokedToMe);
  int get interestedToMe => (front == null ? TorrentClientFront.STATE_NONE: front.interestedToMe);
  int get interestedFromMe => (front == null ? TorrentClientFront.STATE_NONE: front.interestedFromMe);
  bool get amI => (front == null ? false : front.amI);
  bool get isClose => (front == null ? true : front.isClose);
  int get uploadSpeedFromUnchokeFromMe => (front == null ? 0 : front.uploadSpeedFromUnchokeFromMe);
}
