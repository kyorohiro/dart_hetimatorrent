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
          creator.clientB.ai = new TorrentAIBasicDelivery();
          return creator.clientB.targetBlock.writeFullData(new HetimaDataMemory(creator.data));
        }).then((_){
          //
          // connect from clientB to clientA
          List<TorrentClientPeerInfo> infos = creator.clientA.getPeerInfoFromXx((TorrentClientPeerInfo info) {
            if (info.port == creator.clientBPort) {
              return true;
            }
          });
          return creator.clientA.connect(infos[0]);
        }).then((TorrentClientFront frontForBInA) {
          //
          // handshake test
          creator.clientA.onReceiveEvent.listen((TorrentClientMessage info) {
            ticket.complete(info);
          });
          return frontForBInA.sendHandshake().then((_) {
            return ticket.future;
          }).then((TorrentClientMessage info) {
            print("----0004 C----${info.message.id}");
            unit.expect(info.message.id, TorrentMessage.DUMMY_SIGN_SHAKEHAND);
            return frontForBInA;
          });
        }).then((TorrentClientFront frontForBInA) {
          //
          // bitfield
          print("----0004 CC----");
          ticket = new Completer();
          return frontForBInA.sendBitfield(creator.clientB.targetBlock.bitfield).then((_){
            return ticket.future;
          }).then((TorrentClientMessage info) {
            unit.expect(info.message.id, TorrentMessage.SIGN_BITFIELD);
            MessageBitfield bitfield = info.message;
            print("----0004 E----${bitfield.bitfield}");
            unit.expect(creator.clientB.targetBlock.bitfield, bitfield.bitfield);
            return frontForBInA;
          });          
        }).then((TorrentClientFront frontForBinA){
          ticket = new Completer();
          return frontForBinA.sendRequest(0, 0, creator.clientA.targetBlock.blockSize).then((_){
            return ticket.future;
          }).then((TorrentClientMessage message) {
            unit.expect(message.message.id, TorrentMessage.SIGN_PIECE);
            MessagePiece pieceMessage = message.message;
            print("----0007 ${pieceMessage.content}");

          });
        });
      }).whenComplete(() {
        creator.stop();
      }); //
    });
  });
}
