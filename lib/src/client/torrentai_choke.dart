library hetimatorrent.torrent.ai.choke;

import 'dart:core';
import 'dart:async';
import 'torrentclient.dart';
import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';
import 'torrentclient_peerinfos.dart';

class TorrentClientChokeTest {
  List<TorrentClientPeerInfo> extractChokePeerFromUnchoke(TorrentClientPeerInfos infos, int maxOfReplace, int maxOfUnchoke) {
    List<TorrentClientPeerInfo> unchokedPeers = infos.getPeerInfos((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.chokedFromMe == TorrentClientPeerInfo.STATE_OFF && info.amI == false);
    });
    List<TorrentClientPeerInfo> alivePeer = infos.getPeerInfos((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.amI == false);
    });

    List<TorrentClientPeerInfo> ret = [];
    if (alivePeer.length > maxOfUnchoke) {
      unchokedPeers.sort((TorrentClientPeerInfo x, TorrentClientPeerInfo y) {
        return x.uploadSpeedFromUnchokeFromMe - y.uploadSpeedFromUnchokeFromMe;
      });

      int numOfReplace = alivePeer.length - maxOfUnchoke;
      numOfReplace = ((maxOfReplace < numOfReplace) ? maxOfReplace : numOfReplace);
      for (int i = 0; i < numOfReplace && i < unchokedPeers.length; i++) {
        ret.add(unchokedPeers[i]);
      }
    }
    return ret;
  }

  List<TorrentClientPeerInfo> extractUnchokePeerFromChoke(TorrentClientPeerInfos infos, int numOfUnchoke) {
    List<TorrentClientPeerInfo> unchokeInterestedPeers = infos.getPeerInfos((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.interestedToMe == TorrentClientPeerInfo.STATE_ON && info.chokedFromMe == TorrentClientPeerInfo.STATE_ON && info.amI == false);
    });
    List<TorrentClientPeerInfo> unchokeNotInterestedPeers = infos.getPeerInfos((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.interestedToMe != TorrentClientPeerInfo.STATE_ON && info.chokedFromMe == TorrentClientPeerInfo.STATE_ON && info.amI == false);
    });
    unchokeInterestedPeers.shuffle();
    List<TorrentClientPeerInfo> ret = [];
    for (int i = 0; i < unchokeInterestedPeers.length && ret.length < numOfUnchoke; i++) {
      ret.add(unchokeInterestedPeers[i]);
    }
    for (int i = 0; i < unchokeNotInterestedPeers.length && ret.length < numOfUnchoke; i++) {
      ret.add(unchokeNotInterestedPeers[i]);
    }
    return ret;
  }

  TorrentAIChokeTestResult extractChokeAndUnchoke(TorrentClientPeerInfos infos, int maxUnchoke, int maxReplace) {
    List<TorrentClientPeerInfo> unchokeFromMePeers = infos.getPeerInfos((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.chokedFromMe == TorrentClientPeerInfo.STATE_OFF && info.amI == false);
    });
    List<TorrentClientPeerInfo> aliveAndNotChokePeer = infos.getPeerInfos((TorrentClientPeerInfo info) {
      return (info.isClose == false && info.amI == false && info.chokedFromMe != TorrentClientPeerInfo.STATE_OFF);
    });
    List<TorrentClientPeerInfo> chokePeers = extractChokePeerFromUnchoke(infos, maxReplace, maxUnchoke);
    for (TorrentClientPeerInfo info in chokePeers) {
      aliveAndNotChokePeer.remove(info);
    }
    int n = unchokeFromMePeers.length - chokePeers.length;
    List<TorrentClientPeerInfo> unchokePeers = extractUnchokePeerFromChoke(infos, maxUnchoke - n);
    for (TorrentClientPeerInfo info in unchokePeers) {
      aliveAndNotChokePeer.remove(info);
    }

    TorrentAIChokeTestResult ret = new TorrentAIChokeTestResult();
    ret.choke.addAll(chokePeers);
    ret.choke.addAll(aliveAndNotChokePeer);
    ret.unchoke.addAll(unchokePeers);
    return ret;
  }

  Future chokeTest(TorrentClient client, int maxUnchoke) async {
    TorrentAIChokeTestResult r = extractChokeAndUnchoke(client.rawPeerInfos, maxUnchoke, (maxUnchoke ~/ 3 == 0 ? 1 : maxUnchoke ~/ 3));
    for (TorrentClientPeerInfo i in r.choke) {
      try {
        if (i.chokedFromMe != TorrentClientPeerInfo.STATE_ON) {
          await i.front.sendChoke();
        }
      } catch (e) {}
    }
    for (TorrentClientPeerInfo i in r.unchoke) {
      try {
        if (i.chokedFromMe != TorrentClientPeerInfo.STATE_OFF) {
          await i.front.sendUnchoke();
        }
      } catch (e) {}
    }
  }
}

class TorrentAIChokeTestResult {
  List<TorrentClientPeerInfo> choke = [];
  List<TorrentClientPeerInfo> unchoke = [];
}
