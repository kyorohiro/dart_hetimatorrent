library hetimatorrent.dht.knodeai;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../krootingtable.dart';

import '../message/krpcping.dart';
import '../message/krpcfindnode.dart';
import '../message/krpcgetpeers.dart';
import '../kid.dart';
import 'dart:convert';
import '../../util/shufflelinkedlist.dart';

import '../message/krpcmessage.dart';
import '../message/krpcping.dart';
import '../message/krpcfindnode.dart';
import '../message/krpcgetpeers.dart';
import '../message/krpcannounce.dart';
import '../kpeerinfo.dart';
import '../knode.dart';
import 'knodeaifindnode.dart';
import 'knodeiannounce.dart';

abstract class KNodeAI {
  bool get isStart;
  start(KNode node);
  stop(KNode node);
  updateP2PNetwork(KNode node);
  startSearchValue(KNode node, KId infoHash, int port, {getPeerOnly:false});
  researchSearchPeer(KNode node, KId infoHash);
  stopSearchValue(KNode node, KId infoHash);
  onAddNodeFromIPAndPort(KNode node, String ip, int port);
  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query);
  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message);
  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response);
  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message);
  onTicket(KNode);
  startParseLoop(KNode node, EasyParser parser, HetiReceiveUdpInfo info, String deleteKey) {
    a() {
      //
      KrpcMessage.decode(parser, node).then((KrpcMessage message) {
        if (node.verbose == true) {
          print("--->receive[${node.nodeDebugId}] ${info.remoteAddress}:${info.remotePort} ${message}");
        }
        if (message is KrpcResponse) {
          KSendInfo rm = node.removeQueryNameFromTransactionId(UTF8.decode(message.rawMessageMap["t"]));
          this..onReceiveResponse(node, info, message);
          if (rm != null) {
            rm.c.complete(message);
          } else {
            print("----> receive null : [${node.nodeDebugId}] ${info.remoteAddress} ${info.remotePort}");
          }
        } else if (message is KrpcQuery) {
          this.onReceiveQuery(node, info, message);
        } else if (message is KrpcError) {
          this.onReceiveError(node, info, message);
        } else {
          this.onReceiveUnknown(node, info, message);
        }
      }).then((_) {
        a();
      }).catchError((e) {
        parser.resetIndex((parser.buffer as ArrayBuilder).size());
        (parser.buffer as ArrayBuilder).clearInnerBuffer((parser.buffer as ArrayBuilder).size());
        node.buffers.remove(deleteKey);
      });
    }
    a();
  }

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
          _lastAnnouncedTIme = currentTime;
          researchSearchPeer(node, null);
        }
      }
      startTick(node);
    }).catchError((e) {});
  }
}
