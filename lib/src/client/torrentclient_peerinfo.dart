library hetimatorrent.torrent.client.peerinfo;

import 'dart:core';
import '../util/shufflelinkedlist.dart';

import 'torrentclient_front.dart';

class TorrentClientPeerInfoList {
  ShuffleLinkedList<TorrentClientPeerInfo> _peerInfos = new ShuffleLinkedList();
  ShuffleLinkedList<TorrentClientPeerInfo> get rawpeerInfos => _peerInfos;
  int numOfPeerInfo() => _peerInfos.length;

  TorrentClientPeerInfoList() {}

  TorrentClientPeerInfo putPeerInfo(String ip, {int acceptablePort: null, peerId: ""}) {
    for (int i = 0; i < _peerInfos.length; i++) {
      TorrentClientPeerInfo info = _peerInfos.getSequential(i);
      if (info.ip == ip && info.acceptablePort == acceptablePort) {
        // alredy added in peerinfo
        print("putFormTrackerPeerInfo ${ip} ${acceptablePort} --A");
        return info;
      }
    }
    TorrentClientPeerInfo info = new TorrentClientPeerInfo(ip, acceptablePort);
    _peerInfos.addLast(info);
    // alredy added in peerinfo
    print("putFormTrackerPeerInfo ${ip} ${acceptablePort} --B ${_peerInfos.length}");
    return info;
  }

  TorrentClientPeerInfo getPeerInfoFromId(int id) {
    for (int i = 0; i < _peerInfos.length; i++) {
      TorrentClientPeerInfo info = _peerInfos.getSequential(i);
      if (info.id == id) {
        return info;
      }
    }
    return null;
  }

  List<TorrentClientPeerInfo> getPeerInfo(Function filter) {
    List<TorrentClientPeerInfo> ret = [];
    for (int i = 0; i < _peerInfos.length; i++) {
      TorrentClientPeerInfo info = _peerInfos.getSequential(i);
      if (filter(info) == true) {
        ret.add(info);
      }
    }
    return ret;
  }
}

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
