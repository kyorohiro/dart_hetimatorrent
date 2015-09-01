library hetimatorrent.torrent.ai.piece;

import 'dart:core';
import 'torrentclient.dart';
import 'torrentclient_front.dart';
import 'torrentclient_peerinfo.dart';
import '../util/bitfield.dart';
import '../util/bitfield_plus.dart';

class TorrentAIPieceTest {

  BitfieldPlus rand = null;
  List<int> requestedBit = [];
  int downloadPieceLength=16*1024;

  TorrentAIPieceTest(TorrentClient client) {
    rand = new BitfieldPlus(client.targetBlock.rawHead);
    if(downloadPieceLength > client.targetBlock.blockSize) {
      downloadPieceLength =  client.targetBlock.blockSize;
    }
  }
  
  void pieceTest(TorrentClient client, TorrentClientFront front) {
    if(front.amI == true) {
      return;
    }
    if(client.targetBlock.haveAll()) {
      if(front.interestedFromMe == TorrentClientPeerInfo.STATE_ON) {
        front.sendNotInterested();
      }
      return;
    }

    //
    // interest or notinterest
    Bitfield field = client.targetBlock.isNotThrere(front.bitfieldToMe);
    for(int v in requestedBit) {
      field.setIsOn(v, false);
    }
    if(field.isAllOff()) {
      if(front.interestedFromMe != TorrentClientPeerInfo.STATE_OFF && front.currentRequesting.length == 0) {
        front.sendNotInterested();
      }
      return;
    } else {
      if(front.interestedFromMe != TorrentClientPeerInfo.STATE_ON) {
        front.sendInterested();
      }
    }

    //
    // if choke, then end 
    if(front.chokedToMe != TorrentClientPeerInfo.STATE_OFF) {
      return;
    }

    if(0 < front.currentRequesting.length) {
      return;
    }

    //
    // select piece & request
    int targetBit = 0;
    if(front.lastRequestIndex != null && !client.targetBlock.have(front.lastRequestIndex)) {
      targetBit = front.lastRequestIndex;
    } else {
      rand.change(field);
      targetBit = rand.getOnPieceAtRandom();
    }
    List<int> bl =client.targetBlock.getNextBlockPart(targetBit, downloadPieceLength);
    if(bl != null) {
      front.sendRequest(targetBit, bl[0], bl[1]-bl[0]);
    }
  }
}
