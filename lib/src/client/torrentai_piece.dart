library hetimatorrent.torrent.ai.piece;

import 'dart:core';
import 'torrentclient.dart';
import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';
import '../util/bitfield.dart';
import '../util/bitfield_plus.dart';

class TorrentClientPieceTestResult {
  List<TorrentClientPeerInfo> notinterested = [];
  List<TorrentClientPeerInfo> interested = [];
}

class TorrentClientPieceTest {
  BitfieldPlus clientBlockDataInfoProxy = null;
  List<int> requestedBit = [];
  int downloadPieceLength = 16 * 1024;

  TorrentClientPieceTest.fromTorrentClient(TorrentClient client) {
    _init(client.targetBlock.rawHead, client.targetBlock.blockSize);
  }

  TorrentClientPieceTest(Bitfield rawBlockDataInfo, int blockSize) {
    _init(rawBlockDataInfo, blockSize);
  }

  _init(Bitfield rawBlockDataInfo, int blockSize) {
    clientBlockDataInfoProxy = new BitfieldPlus(rawBlockDataInfo);
    if (downloadPieceLength > blockSize) {
      downloadPieceLength = blockSize;
    }
  }

  //, Bitfield clientBlockDataInfo
  TorrentClientPieceTestResult interestTest(TorrentClientPeerInfo info) {
    TorrentClientPieceTestResult ret = new TorrentClientPieceTestResult();
    if (info.amI == true) {
      return ret;
    }
    if (clientBlockDataInfoProxy.isAllOn()) {
      if (info.interestedFromMe == TorrentClientPeerInfo.STATE_ON) {
        ret.notinterested.add(info);
      }
      return ret;
    }

    Bitfield field = Bitfield.relative(info.bitfieldToMe, clientBlockDataInfoProxy);
    for (int v in requestedBit) {
      field.setIsOn(v, false);
    }

    if (field.isAllOff()) {
      if (info.interestedFromMe != TorrentClientPeerInfo.STATE_OFF) {
        ret.notinterested.add(info);
      }
    } else {
      if (info.interestedFromMe != TorrentClientPeerInfo.STATE_ON) {
        ret.interested.add(info);
      }
    }
    return ret;
  }

  pieceTest(TorrentClient client, TorrentClientFront front) {
    if (front.amI == true) {
      return;
    }
    if (client.targetBlock.haveAll()) {
      if (front.interestedFromMe == TorrentClientPeerInfo.STATE_ON) {
        front.sendNotInterested();
      }
      return;
    }

    //
    // interest or notinterest
    Bitfield field = client.targetBlock.isNotThrere(front.bitfieldToMe);
    for (int v in requestedBit) {
      field.setIsOn(v, false);
    }
    if (field.isAllOff()) {
      if (front.interestedFromMe != TorrentClientPeerInfo.STATE_OFF && front.currentRequesting.length == 0) {
        front.sendNotInterested();
      }
      return;
    } else {
      if (front.interestedFromMe != TorrentClientPeerInfo.STATE_ON) {
        front.sendInterested();
      }
    }

    //
    // if choke, then end
    if (front.chokedToMe != TorrentClientPeerInfo.STATE_OFF) {
      return;
    }

    if (0 < front.currentRequesting.length) {
      return;
    }

    //
    // select piece & request
    int targetBit = 0;
    if (front.lastRequestIndex != null && !client.targetBlock.have(front.lastRequestIndex)) {
      targetBit = front.lastRequestIndex;
    } else {
      clientBlockDataInfoProxy.change(field);
      targetBit = clientBlockDataInfoProxy.getOnPieceAtRandom();
    }
    List<int> bl = client.targetBlock.getNextBlockPart(targetBit, downloadPieceLength);
    if (bl != null) {
      front.sendRequest(targetBit, bl[0], bl[1] - bl[0]);
    }
  }
}
