library hetimatorrent.dht.knodeai;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../kid.dart';
import 'dart:convert';

import '../message/krpcmessage.dart';
import '../knode.dart';

abstract class KNodeAI {
  bool get isStart;
  start(KNode node);
  stop(KNode node);
  updateP2PNetwork(KNode node);
  startSearchValue(KNode node, KId infoHash, int port, {getPeerOnly:false});
  researchSearchPeer(KNode node, KId infoHash);
  stopSearchValue(KNode node, KId infoHash);
  onAddNodeFromIPAndPort(KNode node, String ip, int port);
  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcMessage query);
  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcMessage message);
  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcMessage response);
  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message);
  onTicket(KNode);

  int _lastAnnouncedTIme = 0;
  startTick(KNode node) {
    new Future.delayed(new Duration(seconds: node.intervalSecondForMaintenance)).then((_) {
      if (node.isStart == false) {
        return;
      }
      try {
        this.onTicket(node);
      } catch (e) {}
      if (_lastAnnouncedTIme == 0) {
        _lastAnnouncedTIme = new DateTime.now().millisecondsSinceEpoch;
      } else {
        int currentTime = new DateTime.now().millisecondsSinceEpoch;
        if (_lastAnnouncedTIme != 0 && (currentTime - _lastAnnouncedTIme) > node.intervalSecondForAnnounce * 1000) {
          print("time=${(currentTime - _lastAnnouncedTIme)}");
          _lastAnnouncedTIme = currentTime;
          researchSearchPeer(node, null);
        }
      }
      startTick(node);
    }).catchError((e) {});
  }
}
