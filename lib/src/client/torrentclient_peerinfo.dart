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

  List<int> get peerId {
    if (front == null) {
      return [];
    } else {
      return front.targetPeerId;
    }
  }

  /// per sec bytes
  int get speed {
    if (front == null) {
      return 0;
    } else {
      return front.speed;
    }
  }

  /// Me is Hetima
  int get downloadedBytesFromMe {
    if (front == null) {
      return 0;
    } else {
      return front.downloadedBytesFromMe;
    }
  }

  /// Me is Hetima
  int get uploadedBytesToMe {
    if (front == null) {
      return 0;
    } else {
      return front.uploadedBytesToMe;
    }
  }
  /// Me is Hetima
  int get chokedFromMe {
    if (front == null) {
      return 0;
    } else {
      return front.chokedFromMe;
    }
  }
  /// Me is Hetima
  int get chokedToMe {
    if (front == null) {
      return 0;
    } else {
      return front.chokedToMe;
    }
  }
  bool get amI {
    if (front == null) {
      return false;
    } else {
      return front.amI;
    }
  }
}
