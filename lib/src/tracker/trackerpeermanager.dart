library hetimatorrent.torrent.trackermanager;

import 'dart:core';
import 'trackerrequest.dart';
import 'trackerresponse.dart';
import 'trackerpeerinfo.dart';
import '../util/shufflelinkedlist.dart';
import '../file/torrentfile.dart';

class TrackerPeerManager {
  List<int> _managdInfoHash = new List();
  List<int> get managedInfoHash => _managdInfoHash;
  int interval = 60;
  int max = 200;
  ShuffleLinkedList<TrackerPeerInfo> managedPeerAddress = new ShuffleLinkedList();

  TorrentFile _file = null;
  
  TorrentFile get torrentFile => _file;
  TrackerPeerManager(List<int> infoHash, [TorrentFile file=null]) {
    _managdInfoHash = infoHash.toList();
    _file =file;
  }

  int get numOfPeer {
    return 0;
  }

  bool isManagedInfoHash(List<int> infoHash) {
    if (infoHash == null) {
      return false;
    }
    if (_managdInfoHash.length != infoHash.length) {
      return false;
    }
    for (int i = 0; i < _managdInfoHash.length; i++) {
      if (infoHash[i] != _managdInfoHash[i]) {
        return false;
      }
    }
    return true;
  }

  void update(TrackerRequest request) {
    if (!isManagedInfoHash(request.infoHash)) {
      return;
    }
    int current = (new DateTime.now()).millisecondsSinceEpoch;
    managedPeerAddress.removeWithFilter((TrackerPeerInfo info) {
      if ((info.time + (1000 * this.interval * 2)) < current) {
        // remove from list
        return true;
      } else {
        return false;
      }
    });
    TrackerPeerInfo added = managedPeerAddress.addLast(new TrackerPeerInfo(request.peerId, request.address, request.ip, request.port));
    added.update();
    if (managedPeerAddress.length > max) {
      managedPeerAddress.removeHead();
    }
  }

  TrackerResponse createResponse() {
    TrackerResponse response = new TrackerResponse();
    response.interval = this.interval;
    managedPeerAddress.shuffle();
    for (int i = 0; i < 50 && i < managedPeerAddress.length; i++) {
      response.peers.add(managedPeerAddress.getShuffled(i));
    }
    return response;
  }
}
