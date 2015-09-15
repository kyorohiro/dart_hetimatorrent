library hetimatorrent.torrent.client.peerinfos;

import 'dart:core';
import 'torrentclient_peerinfo.dart';
import 'torrentclient_front.dart';

class TorrentClientPeerInfos {
  List<TorrentClientPeerInfo> _peerInfos = [];
  List<TorrentClientPeerInfo> get rawpeerInfos => _peerInfos;
  int get numOfPeerInfo => _peerInfos.length;

  TorrentClientPeerInfos() {}

  List<TorrentClientPeerInfo> getPeerInfos(Function filter) {
    List<TorrentClientPeerInfo> t = [];
    for (TorrentClientPeerInfo x in _peerInfos) {
      if (filter(x)) {
        t.add(x);
      }
    }
    return t;
  }

  void addPeerInfo(TorrentClientPeerInfo info) {
    _peerInfos.add(info);
  }

  //
  // -----
  //
  TorrentClientPeerInfo putPeerInfoFromAddress(String ip, {int acceptablePort: null, peerId: ""}) {
    List<TorrentClientPeerInfo> targetPeers = getPeerInfos((TorrentClientPeerInfo info) {
      return (info.ip == ip && info.port == acceptablePort);
    });
    if (targetPeers.length > 0) {
      return targetPeers.first;
    } else {
      TorrentClientPeerInfo r = new TorrentClientPeerInfoBasic(ip, acceptablePort);
      _peerInfos.add(r);
      return r;
    }
  }

  TorrentClientPeerInfo getPeerInfoFromId(int id) {
    List<TorrentClientPeerInfo> targetPeers = getPeerInfos((TorrentClientPeerInfo info) {
      return (info.id == id);
    });
    return (targetPeers.length > 0 ? targetPeers.first : null);
  }

  clearIfIsEnd({TorrentClientFront front: null}) {
    List<TorrentClientPeerInfo> target = [];
    if (front != null) {
      target = getPeerInfos((TorrentClientPeerInfo l) {
        return l.front == front;
      });
    } else {
      target = _peerInfos;
    }
    List<TorrentClientPeerInfo> rmPeer = [];
    for (TorrentClientPeerInfo info in target) {
      if (info.isEnd) {
        if (info.isAcceptable) {
          info.front = null;
        } else {
          rmPeer.add(info);
        }
      }
    }
    for (TorrentClientPeerInfo info in rmPeer) {
      _peerInfos.remove(info);
    }
  }
}
