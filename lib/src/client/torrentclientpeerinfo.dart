library hetimatorrent.torrent.client.peerinfo;

import 'dart:core';
import '../util/shufflelinkedlist.dart';

import 'torrentclientfront.dart';


class TorrentClientPeerInfoList {
  ShuffleLinkedList<TorrentClientPeerInfo> peerInfos;

  TorrentClientPeerInfoList() {
    peerInfos = new ShuffleLinkedList();
  }

  int numOfPeerInfo() {
    return peerInfos.length;
  }

  //
  // tracker --> ip , port
  // handshake --> ip, peerid,
  //
  TorrentClientPeerInfo putPeerInfoFormTracker(String ip, int port, {peerId: ""}) {
    for (int i = 0; i < peerInfos.length; i++) {
      TorrentClientPeerInfo info = peerInfos.getSequential(i);
      if (info.ip == ip && info.portAcceptable == port) {
        // alredy added in peerinfo
        print("putFormTrackerPeerInfo ${ip} ${port} --A");
        return info;
      }
    }
    TorrentClientPeerInfo info = new TorrentClientPeerInfo.fromTracker(ip, port);
    peerInfos.addLast(info);
    // alredy added in peerinfo
    print("putFormTrackerPeerInfo ${ip} ${port} --B ${peerInfos.length}");
    return info;
  }

  TorrentClientPeerInfo putPeerInfoFormAccept(String ip, int port) {
    for (int i = 0; i < peerInfos.length; i++) {
      TorrentClientPeerInfo info = peerInfos.getSequential(i);
      if (info.ip == ip && info.portCurrent == port) {
        // alredy added in peerinfo
        print("putFormAcceptPeerInfo ${ip} ${port} --A");
        return info;
      }
    }
    TorrentClientPeerInfo info = new TorrentClientPeerInfo.fromTracker(ip, port);
    peerInfos.addLast(info);
    // alredy added in peerinfo
    print("putFormAcceptPeerInfo ${ip} ${port} --B ${peerInfos.length}");
    return info;
  }

  
  TorrentClientPeerInfo getPeerInfoFromId(int id) {
    for (int i = 0; i < peerInfos.length; i++) {
      TorrentClientPeerInfo info = peerInfos.getSequential(i);
      if (info.id == id) {
        return info;
      }
    }
    return null;
  }

  List<TorrentClientPeerInfo> getPeerInfo(Function filter) {
    List<TorrentClientPeerInfo> ret = [];
    for (int i = 0; i < peerInfos.length; i++) {
      TorrentClientPeerInfo info = peerInfos.getSequential(i);
      if(filter(info) == true) {
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
  int portAcceptable = 0;
  int portCurrent = 0;
  TorrentClientFront front = null;
  bool get isAcceptable => portAcceptable != 0;


  TorrentClientPeerInfo.fromTracker(String ip, int port) {
    this.id = ++nid;
    this.ip = ip;
    this.portAcceptable = port;
  }

  TorrentClientPeerInfo.fromAccept(String ip, int portCurrent) {
    this.id = ++nid;
    this.ip = ip;
    this.portCurrent = portCurrent;
    this.peerId.addAll(peerId);
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
