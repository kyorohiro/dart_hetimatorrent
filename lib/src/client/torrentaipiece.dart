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

class PieceTest {

  PieceTest(TorrentClient client) {
  }
  
  void pieceTest(TorrentClient client, TorrentClientFront front) {
    //
    // think interest or notinterest
    //
    Bitfield field = client.targetBlock.isNotThrere(front.bitfieldToMe);
    if(field.isAllOff()) {
      if(front.interestedFromMe != TorrentClientFront.STATE_OFF) {
        front.sendNotInterested();
      }
      return;
    } else {
      if(front.interestedFromMe != TorrentClientFront.STATE_ON) {
        front.sendInterested();
      }
    }

    //
    //
    //
    if(front.chokedToMe == true) {
      return;
    }
    
  }
}
