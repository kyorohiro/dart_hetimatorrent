library hetimatorrent.torrent.ai.piece;

import 'dart:core';
import 'torrentclient.dart';
import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';
import '../util/bitfield.dart';
import '../util/blockdata.dart';
import '../util/bitfield_plus.dart';

class TorrentClientPieceTestResultA {
  List<TorrentClientPeerInfo> notinterested = [];
  List<TorrentClientPeerInfo> interested = [];
}

class TorrentClientPieceTestResultB {
  TorrentClientPeerInfo request = null;
  List<BlockDataGetNextBlockPartResult> begineEnd = null;
  int targetBit = 0;
}

class TorrentClientPieceTest {
  List<int> requestedBit = [];
  int downloadPieceLength = 16 * 1024;
  int maxOfRequest = 5;

  TorrentClientPieceTest.fromTorrentClient(TorrentClient client, {int downloadPieceLength: 16 * 1024, int maxOfRequest: 3}) {
    _init(client.targetBlock.rawHead, client.targetBlock.blockSize, downloadPieceLength, maxOfRequest);
  }

  TorrentClientPieceTest(Bitfield rawBlockDataInfo, int blockSize, {int downloadPieceLength: 16 * 1024, int maxOfRequest: 3}) {
    _init(rawBlockDataInfo, blockSize, downloadPieceLength, maxOfRequest);
  }

  _init(Bitfield rawBlockDataInfo, int blockSize, int downloadPieceLength, maxOfRequest) {
    this.downloadPieceLength = downloadPieceLength;
    this.maxOfRequest = maxOfRequest;

    if (downloadPieceLength > blockSize) {
      downloadPieceLength = blockSize;
    }
  }

  //, Bitfield clientBlockDataInfo
  TorrentClientPieceTestResultA interestTest(BlockData blockData, TorrentClientPeerInfo info) {
    TorrentClientPieceTestResultA ret = new TorrentClientPieceTestResultA();
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
      if(targetBit < 0) {
        print("### A -1");
      }
    } else {
      BitfieldPlus _cash = blockData.isNotThrere(info.bitfieldToMe);
      targetBit = _cash.getOnPieceAtRandom();
      if(targetBit < 0) {
        print("### B -1");
      }
    }

    List<BlockDataGetNextBlockPartResult> bl = blockData.getNextBlockParts(targetBit, downloadPieceLength, userReserve: true);
    if(bl.length == 0) {
      bl = blockData.getNextBlockParts(targetBit, downloadPieceLength, userReserve: false);
    }
    ret.begineEnd = bl;
    ret.request = info;
    ret.targetBit = targetBit;
    return ret;
  }

  pieceTest(TorrentClient client, TorrentClientPeerInfo info) {
    TorrentClientFront front = info.front;
    if (front == null || front.amI == true) {
      return;
    }
    TorrentClientPieceTestResultA r = interestTest(client.targetBlock, info);
    for (TorrentClientPeerInfo i in r.interested) {
      if (i != null) {
        i.front.sendInterested();
      }
    }
    for (TorrentClientPeerInfo i in r.notinterested) {
      if (i != null) {
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
    TorrentClientPieceTestResultB r1 = requestTest(client.targetBlock, info);
    if (r1.request != null && r1.request.front != null) {
    //  print("-->${r1.begineEnd.length} [${r1.targetBit}] 0:${r1.begineEnd[0].begin} #:${r1.begineEnd[r1.begineEnd.length-1].begin}");
      for (int i = 0; i < this.maxOfRequest && i < r1.begineEnd.length; i++) {
    //  for (int i = 0; i < r1.begineEnd.length; i++) {
        BlockDataGetNextBlockPartResult r = r1.begineEnd[i];
        client.targetBlock.reservePartBlock(r1.targetBit, r.begin, r.end - r.begin);
        r1.request.front.sendRequest(r1.targetBit, r.begin, r.end - r.begin);
      }
    }
  }
}
