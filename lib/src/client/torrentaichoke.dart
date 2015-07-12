library hetimatorrent.torrent.ai.choke;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';
import 'package:hetimacore/hetimacore.dart';
import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';
import 'torrentclientmessage.dart';

class ChokeTest {
  void chokeTest(TorrentClient client, int _maxUnchoke) {
    List<TorrentClientPeerInfo> unchokeInterestedPeer = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      if (info.front != null && info.front.isClose == false && info.front.interestedToMe == TorrentClientFront.STATE_ON && info.front.chokedFromMe == TorrentClientFront.STATE_ON) {
        return true;
      }
      return false;
    });

    List<TorrentClientPeerInfo> newPeer = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      if (info.front != null && info.front.isClose == false && info.front.chokedFromMe == TorrentClientFront.STATE_NONE) {
        return true;
      }
      return false;
    });

    List<TorrentClientPeerInfo> chokedInterestPeer = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      if (info.front != null && info.front.isClose == false && info.front.chokedFromMe == TorrentClientFront.STATE_OFF) {
        return true;
      }
      return false;
    });

    List<TorrentClientPeerInfo> nextUnchoke = [];
    nextUnchoke.addAll(newPeer);
    nextUnchoke.addAll(chokedInterestPeer);

    //
    //
    // 2 peer change
    unchokeInterestedPeer.shuffle();
    if (unchokeInterestedPeer.length > (_maxUnchoke - 2)) {
      unchokeInterestedPeer.sort((TorrentClientPeerInfo x, TorrentClientPeerInfo y) {
        return x.front.uploadSpeedFromUnchokeFromMe - y.front.uploadSpeedFromUnchokeFromMe;
      });
      unchokeInterestedPeer.removeLast().front.sendChoke();
      if (unchokeInterestedPeer.length < (_maxUnchoke - 2)) {
        unchokeInterestedPeer.removeLast().front.sendChoke();
      }
    }

    //
    // add include peer
    //
    int unchokeNum = _maxUnchoke - unchokeInterestedPeer.length;
    nextUnchoke.shuffle();
    int numOfSendedUnchoke = 0;

    // first intersted peer
    for (int i = 0; i < unchokeNum && 0 < nextUnchoke.length; i++) {
      TorrentClientPeerInfo info = nextUnchoke.removeLast();
      if (info.front.amI == false &&info.front.interestedToMe == TorrentClientFront.STATE_ON || info.front.interestedToMe == TorrentClientFront.STATE_NONE) {
        info.front.sendUnchoke();
        numOfSendedUnchoke++;
      }
    }

    // secound notinterested peer
    for (int i = 0; i < (_maxUnchoke - numOfSendedUnchoke) && 0 < nextUnchoke.length; i++) {
      TorrentClientPeerInfo info = nextUnchoke.removeLast();
      if (info.front.amI == false && info.front.interestedToMe == TorrentClientFront.STATE_OFF) {
        info.front.sendUnchoke();
      }
    }

    //
    // send unchoke
    for (TorrentClientPeerInfo info in nextUnchoke) {
      if (info.chokedFromMe == false) {
        info.front.sendChoke();
      }
    }
  }
}
