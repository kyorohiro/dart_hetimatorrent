import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';

import 'dart:convert';
import 'dart:async';
import 'package:hetimatorrent/src/test/twoClientOneTracker.dart';

void main() {
  unit.group("torrent file", () {
    unit.test("001 testdata/1k.txt.torrent", () {
      Completer<TorrentClientMessage> ticket = new Completer();
      TestCaseCreator2Client1Tracker creator = new TestCaseCreator2Client1Tracker();
      return new Future(() {
        return creator.createTestEnv_startAndRequestToTracker().then((_) {
          return null;
        }).then((_) {
          //
          // clientB have fullset data
          return creator.clientB.targetBlock.writeFullData(new HetimaDataMemory(creator.data));
        }).then((_){
          //
          // connect from clientB to clientA
          List<TorrentClientPeerInfo> infos = creator.clientB.getPeerInfoFromXx((TorrentClientPeerInfo info) {
            if (info.portAcceptable == creator.clientAPort) {
              return true;
            }
          });
          return creator.clientB.connect(infos[0]);
        }).then((TorrentClientFront frontForAInB) {
          //
          // handshake test
          creator.clientA.onReceiveEvent.listen((TorrentClientMessage info) {
            ticket.complete(info);
          });
          return frontForAInB.sendHandshake().then((_) {
            return ticket.future;
          }).then((TorrentClientMessage info) {
            print("----0004 C----${info.message.id}");
            unit.expect(info.message.id, TorrentMessage.DUMMY_SIGN_SHAKEHAND);
            return frontForAInB;
          });
        }).then((TorrentClientFront frontForAInB) {
          //
          // bitfield
          ticket = new Completer();
          return frontForAInB.sendBitfield(creator.clientB.targetBlock.bitfield).then((_){
            return ticket.future;
          }).then((TorrentClientMessage info) {
            unit.expect(info.message.id, TorrentMessage.SIGN_BITFIELD);
            MessageBitfield bitfield = info.message;
            print("----0004 E----${bitfield.bitfield}");
            unit.expect(creator.clientB.targetBlock.bitfield, bitfield.bitfield);
          });
        });
      }).whenComplete(() {
        creator.stop();
      }); //
    });
  });
}
