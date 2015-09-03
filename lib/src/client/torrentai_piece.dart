library hetimatorrent.torrent.ai.piece;

import 'dart:core';
import 'torrentclient.dart';
import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';
import '../util/bitfield.dart';
import '../util/blockdata.dart';
import '../util/bitfield_plus.dart';

class TorrentClientPieceTestResult {
  List<TorrentClientPeerInfo> notinterested = [];
  List<TorrentClientPeerInfo> interested = [];

}
class TorrentClientPieceTestResultB {
  TorrentClientPeerInfo request = null;
  int begin = 0;
  int end = 0;
  int targetBit = 0;
}

class TorrentClientPieceTest {
  List<int> requestedBit = [];
  int downloadPieceLength = 16 * 1024;
//  BitfieldPlus _cash = null;
  TorrentClientPieceTest.fromTorrentClient(TorrentClient client) {
    _init(client.targetBlock.rawHead, client.targetBlock.blockSize);
  }

  TorrentClientPieceTest(Bitfield rawBlockDataInfo, int blockSize) {
    _init(rawBlockDataInfo, blockSize);
  }

  _init(Bitfield rawBlockDataInfo, int blockSize) {
    if (downloadPieceLength > blockSize) {
      downloadPieceLength = blockSize;
    }
  }

  //, Bitfield clientBlockDataInfo
  TorrentClientPieceTestResult interestTest(BlockData blockData, TorrentClientPeerInfo info) {
    TorrentClientPieceTestResult ret = new TorrentClientPieceTestResult();
    if (info.amI == true) {
      return ret;
    }
    if (blockData.haveAll()) {
      if (info.interestedFromMe != TorrentClientPeerInfo.STATE_OFF) {
        ret.notinterested.add(info);
      }
      return ret;
    }

    BitfieldPlus _cash = blockData.isNotThrere(info.bitfieldToMe);
    for (int v in requestedBit) {
      _cash.setIsOn(v, false);
    }

    if (_cash.isAllOff()) {
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

  TorrentClientPieceTestResultB requestTest(BlockData blockData, TorrentClientPeerInfo info) {
    TorrentClientPieceTestResultB ret = new TorrentClientPieceTestResultB();
    TorrentClientFront front = info.front;
    if (info.amI == true) {
      return ret;
    }

    int targetBit = 0;
    if (front.lastRequestIndex != null && !blockData.have(front.lastRequestIndex)) {
      targetBit = front.lastRequestIndex;
    } else {
      BitfieldPlus _cash = blockData.isNotThrere(info.bitfieldToMe);
      targetBit = _cash.getOnPieceAtRandom();
    }
    List<int> bl = blockData.getNextBlockPart(targetBit, downloadPieceLength);
    if (bl != null) {
      ret.begin = bl[0];
      ret.end = bl[1];
      ret.request = info;
    }
    ret.targetBit = targetBit;
    return ret;
  }

  pieceTest(TorrentClient client, TorrentClientPeerInfo info) {
    TorrentClientFront front = info.front;
    if (front == null || front.amI == true) {
      return;
    }
    TorrentClientPieceTestResult r = interestTest(client.targetBlock, info);
    for(TorrentClientPeerInfo i in r.interested) {
      if(i != null) {
       i.front.sendInterested();
      }
    }
    for(TorrentClientPeerInfo i in r.notinterested) {
      if(i != null) {
       i.front.sendNotInterested();
      }
    }

    //
    // if choke, then end
    if (client.targetBlock.haveAll() == true || front.chokedToMe != TorrentClientPeerInfo.STATE_OFF) {
      return;
    }

    //
    // now requesting
    if (0 < front.currentRequesting.length) {
      return;
    }

    //
    // select piece & request
    TorrentClientPieceTestResultB  r1 = requestTest(client.targetBlock, info);
    if(r1.request != null && r1.request.front != null) {
      r1.request.front.sendRequest(r1.targetBit, r1.begin,r1.end-r1.begin);
    }
  }
}
