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
class PieceTest {

  DDBitfield rand = null;
  List<int> requestedBit = [];

  PieceTest(TorrentClient client) {
    rand = new DDBitfield(client.targetBlock.rawBitfield);
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
    if(front.chokedToMe == true) {
      return;
    }

    if(0 < front.currentRequesting.length) {
      return;
    }

    //
    //
    rand.change(field);
    int targetBit = rand.getOnPieceAtRandom();
    front.sendRequest(targetBit, 0, client.targetBlock.blockSize);
  }
}
