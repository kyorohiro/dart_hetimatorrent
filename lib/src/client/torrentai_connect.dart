library hetimatorrent.torrent.ai.connect;

import 'dart:core';
import 'dart:async';
import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';

class ConnectTest {
  Future connectTest(TorrentClientPeerInfo info, TorrentClient client, int _maxConnect) async {
    if (!(info.front == null || info.front.isClose == true)) {
      return {};
    }

    List<TorrentClientPeerInfo> connectedPeers = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      if (info.front == null || info.front.isClose == true) {
        return false;
      } else {
        return true;
      }
    });

    if (connectedPeers.length < _maxConnect && (info.front == null || info.front.amI == false)) {
      if ((info.front != null && client.targetBlock.haveAll() == true && info.front.bitfieldToMe.isAllOn())) {
        return null;
      }
      if (info.front != null && info.front.isClose == false) {
        return null;
      }
      if (false == client.isStart) {
        return null;
      }
      try {
        TorrentClientFront f = await client.connect(info);
        return f.sendHandshake();
      } catch (e) {
        try {
          if (info.front != null) {
            info.front.close();
          }
        } catch (e) {
          ;
        }
      }
    }
  }
}
