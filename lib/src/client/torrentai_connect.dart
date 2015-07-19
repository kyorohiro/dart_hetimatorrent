library hetimatorrent.torrent.ai.connect;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';
import 'package:hetimacore/hetimacore.dart';
import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';
import 'torrentclientmessage.dart';
import 'torrentai_choke.dart';
import 'torrentai_piece.dart';
import 'torrentai.dart';

class ConnectTest {
  Future connectTest(TorrentClientPeerInfo info, TorrentClient client, int _maxConnect) {
    return new Future(() {
      if (info.front == null || info.front.isClose == true) {
        List<TorrentClientPeerInfo> connects = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
          if (info.front == null || info.front.isClose == true) {
            return false;
          } else {
            return true;
          }
        });
        if (connects.length < _maxConnect && (info.front == null || info.front.amI == false)) {
          if ((info.front != null && client.targetBlock.haveAll() == true && info.front.bitfieldToMe.isAllOn())) {
            return null;
          }
          if (info.front != null && info.front.isClose == false) {
            return null;
          }
          if (false == client.isStart) {
            return null;
          }
          return client.connect(info).then((TorrentClientFront f) {
            return f.sendHandshake();
          }).catchError((e) {
            try {
              if (info.front != null) {
                info.front.close();
              }
            } catch (e) {
              ;
            }
          });
        }
      }
    });
  }
}
