library hetimatorrent.torrent.client.peerinfo;

import 'dart:core';
import 'torrentclient_front.dart';

class TorrentClientPeerInfo {
  static int nid = 0;
  int id = 0;

  String ip = "";
  int acceptablePort = 0;
  TorrentClientFront front = null;
  bool get isAcceptable => acceptablePort != 0;

  TorrentClientPeerInfo(String ip, int port) {
    this.id = ++nid;
    this.ip = ip;
    this.acceptablePort = port;
  }

  List<int> get peerId => (front == null ? [] : front.targetPeerId);
  int get speed => (front == null ? 0 : front.speed);
  int get downloadedBytesFromMe => (front == null ? 0 : front.downloadedBytesFromMe);
  int get uploadedBytesToMe => (front == null ? 0 : front.uploadedBytesToMe);
  int get chokedFromMe => (front == null ? 0 : front.chokedFromMe);
  int get chokedToMe => (front == null ? 0 : front.chokedToMe);
  int get interestedToMe => (front == null ? 0 : front.interestedToMe);
  int get interestedFromMe => (front == null ? 0 : front.interestedFromMe);
  bool get amI => (front == null ? false : front.amI);
  bool get isClose => (front == null ? false : front.isClose);
}
