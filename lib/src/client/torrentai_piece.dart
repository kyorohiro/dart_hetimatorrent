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
class TorrentClientPieceTestResultB {
  TorrentClientPeerInfo request = null;
  int begin = 0;
  int end = 0;
  int targetBit = 0;
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
      if (info.interestedFromMe != TorrentClientPeerInfo.STATE_OFF) {
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

  TorrentClientPieceTestResultB requestTest(TorrentClient client, TorrentClientPeerInfo info) {
    TorrentClientPieceTestResultB ret = new TorrentClientPieceTestResultB();
    TorrentClientFront front = info.front;
    //
    // select piece & request
    //
    Bitfield field = Bitfield.relative(info.bitfieldToMe, clientBlockDataInfoProxy);
    int targetBit = 0;
    if (front.lastRequestIndex != null && !client.targetBlock.have(front.lastRequestIndex)) {
      targetBit = front.lastRequestIndex;
    } else {
      clientBlockDataInfoProxy.change(field);
      targetBit = clientBlockDataInfoProxy.getOnPieceAtRandom();
    }
    List<int> bl = client.targetBlock.getNextBlockPart(targetBit, downloadPieceLength);
    if (bl != null) {
      ret.begin = bl[0];
      ret.end = bl[1];
    }
    ret.targetBit = targetBit;
    return ret;
  }

  pieceTest(TorrentClient client, TorrentClientPeerInfo info) {
    TorrentClientFront front = info.front;
    if (front == null || front.amI == true) {
      return;
    }
    TorrentClientPieceTestResult r = interestTest(info);
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
    if (clientBlockDataInfoProxy.isAllOn() == true || front.chokedToMe != TorrentClientPeerInfo.STATE_OFF) {
      return;
    }

    //
    // now requesting
    if (0 < front.currentRequesting.length) {
      return;
    }

    //
    // select piece & request
    TorrentClientPieceTestResultB  r1 = requestTest(client, info);
    if(r1.request != null && r1.request.front != null) {
      r1.request.front.sendRequest(r1.targetBit, r1.begin,r1.end-r1.begin);
    }
  }
}
