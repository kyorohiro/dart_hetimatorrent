library hetimatorrent.torrent.client.peerinfos;

import 'dart:core';
import '../util/shufflelinkedlist.dart';

import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';

class TorrentClientPeerInfos {
  ShuffleLinkedList<TorrentClientPeerInfo> _peerInfos = new ShuffleLinkedList();
  ShuffleLinkedList<TorrentClientPeerInfo> get rawpeerInfos => _peerInfos;
  int numOfPeerInfo() => _peerInfos.length;

  TorrentClientPeerInfos() {}

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

