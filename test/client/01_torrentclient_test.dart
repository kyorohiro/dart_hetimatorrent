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
      TestCaseCreator2Client1Tracker creator = new TestCaseCreator2Client1Tracker();
      return  new Future(() {
        return creator.createTestEnv_startAndRequestToTracker().then((_){
          return null;
        }).then((_){
          List<TorrentClientPeerInfo> infos = creator.clientB.getPeerInfoFromXx((TorrentClientPeerInfo info) {
            if(info.port == creator.clientAPort) {
              return true;
            }
          });
          return creator.clientB.connect(infos[0]);
        }).then((TorrentClientFront front) {
          print("----0004 A----");
          return front.sendHandshake().then((_){
            print("----0004 B----");
            return null;
          });
        }).then((_){
          print("----0004 C----");
        });
      }).whenComplete(() {
        print("----0005----");
        creator.stop();
      });//
    });
  });
}
