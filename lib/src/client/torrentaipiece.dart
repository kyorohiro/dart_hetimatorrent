library hetimatorrent.torrent.ai.piece;

import 'dart:core';
import 'dart:async';
import '../message/message.dart';
import 'package:hetimacore/hetimacore.dart';
import 'torrentclient.dart';
import 'torrentclientfront.dart';
import 'torrentclientpeerinfo.dart';
import 'torrentclientmessage.dart';
import '../util/bitfield.dart';
import '../util/ddbitfield.dart';
import '../util/pieceinfo.dart';

class PieceTest {

  DDBitfield rand = null;
  List<int> requestedBit = [];
  int downloadPieceLength=16*1024;

  PieceTest(TorrentClient client) {
    rand = new DDBitfield(client.targetBlock.rawBitfield);
    if(downloadPieceLength > client.targetBlock.blockSize) {
      downloadPieceLength =  client.targetBlock.blockSize;
    }
  }
  
  void pieceTest(TorrentClient client, TorrentClientFront front) {
    if(front.amI == true) {
      return;
    }
    if(client.targetBlock.haveAll()) {
      if(front.interestedFromMe == TorrentClientFront.STATE_ON) {
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
      if(front.interestedFromMe != TorrentClientFront.STATE_OFF && front.currentRequesting.length == 0) {
        front.sendNotInterested();
      }
      return;
    } else {
      if(front.interestedFromMe != TorrentClientFront.STATE_ON) {
        front.sendInterested();
      }
    }

    //
    // if choke, then end 
    if(front.chokedToMe != TorrentClientFront.STATE_OFF) {
      return;
    }

    if(0 < front.currentRequesting.length) {
      return;
    }

    //
    // select piece & request
    int targetBit = 0;
    if(front.lastRequestIndex != null && client.targetBlock.have(front.lastRequestIndex)) {
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
