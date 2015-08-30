library hetimatorrent.torrent.client.peerinfos;

import 'dart:core';
import '../util/shufflelinkedlist.dart';

import 'torrentclient_peerinfo.dart';

class TorrentClientPeerInfos {
  ShuffleLinkedList<TorrentClientPeerInfo> _peerInfos = new ShuffleLinkedList();
  ShuffleLinkedList<TorrentClientPeerInfo> get rawpeerInfos => _peerInfos;
  int numOfPeerInfo() => _peerInfos.length;

  TorrentClientPeerInfos() {}

  TorrentClientPeerInfo putPeerInfo(String ip, {int acceptablePort: null, peerId: ""}) {
    List<TorrentClientPeerInfo> targetPeers = _peerInfos.getWithFilter((TorrentClientPeerInfo info){
      return (info.ip == ip && info.acceptablePort == acceptablePort);
    });
    if(targetPeers.length > 0) {
      return targetPeers.first;
    }

    TorrentClientPeerInfo info = new TorrentClientPeerInfo(ip, acceptablePort);
    return _peerInfos.addLast(info);
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

