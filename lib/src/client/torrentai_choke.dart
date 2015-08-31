library hetimatorrent.torrent.ai.choke;

import 'dart:core';
import 'dart:async';
import 'torrentclient.dart';
import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';
import 'torrentclient_peerinfos.dart';

class TorrentAIChokeTest {
  List<TorrentClientPeerInfo> getUnchokeInterestedPeers(TorrentClientPeerInfos infos) {
    return infos.getPeerInfo((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.interestedToMe == TorrentClientFront.STATE_ON && info.chokedFromMe == TorrentClientFront.STATE_ON);
    });
  }

  List<TorrentClientPeerInfo> getNewcomerPeers(TorrentClientPeerInfos infos) {
    return infos.getPeerInfo((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.chokedFromMe == TorrentClientFront.STATE_NONE);
    });
  }

  List<TorrentClientPeerInfo> getChokedAndInterestPeers(TorrentClientPeerInfos infos) {
    return infos.getPeerInfo((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.chokedFromMe == TorrentClientFront.STATE_OFF);
    });
  }

  List<TorrentClientPeerInfo> extractChokePeerFromUnchokePeers(TorrentClientPeerInfos infos, int numOfReplace, int maxOfUnchoke) {
    List<TorrentClientPeerInfo> ret = [];
    List<TorrentClientPeerInfo> unchokeFromMePeers = infos.getPeerInfo((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.chokedFromMe == TorrentClientFront.STATE_OFF);
    });
    List<TorrentClientPeerInfo> alivePeer = infos.getPeerInfo((TorrentClientPeerInfo info) {
      return (info.isClose == false);
    });
    if (alivePeer.length > maxOfUnchoke) {
      unchokeFromMePeers.sort((TorrentClientPeerInfo x, TorrentClientPeerInfo y) {
        return x.uploadSpeedFromUnchokeFromMe - y.uploadSpeedFromUnchokeFromMe;
      });

      numOfReplace = (numOfReplace < (alivePeer.length - maxOfUnchoke) ? numOfReplace : (alivePeer.length - maxOfUnchoke));
      for (int i = 0; i < numOfReplace&& i<unchokeFromMePeers.length; i++) {
        ret.add(unchokeFromMePeers[i]);
      }
    }
    return ret;
  }

  List<TorrentClientPeerInfo> extractUnchokePeerFromChoke(TorrentClientPeerInfos infos, int numOfUnchoke) {
    List<TorrentClientPeerInfo> unchokeInterestedPeers = infos.getPeerInfo((TorrentClientPeerInfo info) {
      return (info.isClose == false &&
          info.interestedToMe == TorrentClientFront.STATE_ON &&
          info.chokedFromMe == TorrentClientFront.STATE_ON &&
          info.amI == false);
    });
    List<TorrentClientPeerInfo> unchokeNotInterestedPeers = infos.getPeerInfo((TorrentClientPeerInfo info) {
      return (info.isClose == false &&
          info.interestedToMe != TorrentClientFront.STATE_ON &&
          info.chokedFromMe == TorrentClientFront.STATE_ON &&
          info.amI == false);
    });
    unchokeInterestedPeers.shuffle();
    List<TorrentClientPeerInfo> ret = [];
    for (int i = 0; i < unchokeInterestedPeers.length &&  ret.length < numOfUnchoke; i++) {
      ret.add(unchokeInterestedPeers[i]);
    }
    for (int i = 0; i < unchokeNotInterestedPeers.length &&  ret.length < numOfUnchoke; i++) {
      ret.add(unchokeNotInterestedPeers[i]);
    }

    return ret;
  }


  Future chokeTestA(TorrentClient client, int maxUnchoke, int maxReplace) async {
    List<TorrentClientPeerInfo> chokePeers = extractChokePeerFromUnchokePeers(client.rawPeerInfos, maxReplace, maxUnchoke);
    for (TorrentClientPeerInfo info in chokePeers) {
      await info.front.sendChoke();
    }
    List<TorrentClientPeerInfo> unchokePeers = extractUnchokePeerFromChoke(client.rawPeerInfos, 3);
    for (TorrentClientPeerInfo info in unchokePeers) {
      await info.front.sendUnchoke();
    }
    List<TorrentClientPeerInfo> unchokePeersB = extractUnchokePeerFromChoke(client.rawPeerInfos, 3);
    for (TorrentClientPeerInfo info in unchokePeersB) {
      await info.front.sendUnchoke();
    }
  }

  void chokeTest(TorrentClient client, int _maxUnchoke) {
    List<TorrentClientPeerInfo> unchokeInterestedPeers = getUnchokeInterestedPeers(client.rawPeerInfos);
    List<TorrentClientPeerInfo> newcomerPeers = getNewcomerPeers(client.rawPeerInfos);
    List<TorrentClientPeerInfo> chokedAndInterestPeers = getChokedAndInterestPeers(client.rawPeerInfos);

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
      if (info.amI == false && info.interestedToMe == TorrentClientFront.STATE_ON || info.interestedToMe == TorrentClientFront.STATE_NONE) {
        if (info.front.chokedFromMe != TorrentClientFront.STATE_OFF) {
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
        if (info.chokedFromMe != TorrentClientFront.STATE_OFF) {
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
