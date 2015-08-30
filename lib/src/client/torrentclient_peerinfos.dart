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
    List<TorrentClientPeerInfo> targetPeers = _peerInfos.getWithFilter((TorrentClientPeerInfo info) {
      return (info.ip == ip && info.acceptablePort == acceptablePort);
    });
    return (targetPeers.length > 0 ? targetPeers.first : _peerInfos.addLast(new TorrentClientPeerInfoBasic(ip, acceptablePort)));
  }

  TorrentClientPeerInfo getPeerInfoFromId(int id) {
    List<TorrentClientPeerInfo> targetPeers = _peerInfos.getWithFilter((TorrentClientPeerInfo info) {
      return (info.id == id);
    });
    return (targetPeers.length > 0 ? targetPeers.first : null);
  }

  List<TorrentClientPeerInfo> getPeerInfo(Function filter) {
    List<TorrentClientPeerInfo> targetPeers = _peerInfos.getWithFilter((TorrentClientPeerInfo info) {
      return (filter(info) == true);
    });
    return targetPeers;
  }
  
  
}
