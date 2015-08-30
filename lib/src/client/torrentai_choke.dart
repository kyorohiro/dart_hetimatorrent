library hetimatorrent.torrent.ai.choke;

import 'dart:core';
import 'torrentclient.dart';
import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';

class TorrentAIChokeTest {

  void chokeTest(TorrentClient client, int _maxUnchoke) {
    List<TorrentClientPeerInfo> unchokeInterestedPeers = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      return  (
          info.isClose == false && 
          info.interestedToMe == TorrentClientFront.STATE_ON &&
          info.chokedFromMe == TorrentClientFront.STATE_ON);
    });

    List<TorrentClientPeerInfo> newcomerPeers = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      return (
          info.isClose == false && 
          info.chokedFromMe == TorrentClientFront.STATE_NONE);
    });

    List<TorrentClientPeerInfo> chokedAndInterestPeers = client.rawPeerInfos.getPeerInfo((TorrentClientPeerInfo info) {
      return (
          info.isClose == false &&
          info.chokedFromMe == TorrentClientFront.STATE_OFF);
    });

    List<TorrentClientPeerInfo> nextUnchoke = [];
    nextUnchoke.addAll(newcomerPeers);
    nextUnchoke.addAll(chokedAndInterestPeers);

    //
    // 2 peer change
    unchokeInterestedPeers.shuffle();
    if (unchokeInterestedPeers.length > (_maxUnchoke - 2)) {
      unchokeInterestedPeers.sort((TorrentClientPeerInfo x, TorrentClientPeerInfo y) {
        return x.front.uploadSpeedFromUnchokeFromMe - y.front.uploadSpeedFromUnchokeFromMe;
      });
      unchokeInterestedPeers.removeLast().front.sendChoke();
      if (unchokeInterestedPeers.length < (_maxUnchoke - 2)) {
        unchokeInterestedPeers.removeLast().front.sendChoke();
      }
    }

    //
    // add include peer
    int unchokeNum = _maxUnchoke - unchokeInterestedPeers.length;
    nextUnchoke.shuffle();
    int numOfSendedUnchoke = 0;

    //
    // first intersted peer
    for (int i = 0; i < unchokeNum && 0 < nextUnchoke.length; i++) {
      TorrentClientPeerInfo info = nextUnchoke.removeLast();
      if (info.amI == false &&
          info.interestedToMe == TorrentClientFront.STATE_ON || info.interestedToMe == TorrentClientFront.STATE_NONE) {
        if(info.front.chokedFromMe != TorrentClientFront.STATE_OFF) {
          info.front.sendUnchoke();
        }
        numOfSendedUnchoke++;
      }
    }

    //
    // secound notinterested peer
    for (int i = 0; i < (_maxUnchoke - numOfSendedUnchoke) && 0 < nextUnchoke.length; i++) {
      TorrentClientPeerInfo info = nextUnchoke.removeLast();
      if (info.amI == false && info.interestedToMe == TorrentClientFront.STATE_OFF) {
        if(info.chokedFromMe != TorrentClientFront.STATE_OFF) {
          info.front.sendUnchoke();
        }
      }
    }

    //
    // send unchoke
    for (TorrentClientPeerInfo info in nextUnchoke) {
      if (info.chokedFromMe != TorrentClientFront.STATE_ON) {
        info.front.sendChoke();
      }
    }
  }
}
