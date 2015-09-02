library peerinfo.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'dart:math';

void main() {
  unit.group('A group of tests', () {
    unit.test("extractChokePeerFromUnchoke", () {
      TorrentClientPeerInfo a = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8081
        ..chokedFromMe = TorrentClientPeerInfo.STATE_OFF
        ..downloadedBytesFromMe = 100
        ..isClose = false;
      TorrentClientPeerInfo b = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8082
        ..chokedFromMe = TorrentClientPeerInfo.STATE_OFF
        ..downloadedBytesFromMe = 101
        ..isClose = false;
      TorrentClientPeerInfo c = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8083
        ..chokedFromMe = TorrentClientPeerInfo.STATE_OFF
        ..downloadedBytesFromMe = 102
        ..isClose = false;
      TorrentClientPeerInfo d = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8083
        ..chokedFromMe = TorrentClientPeerInfo.STATE_OFF
        ..downloadedBytesFromMe = 103
        ..isClose = false;
      TorrentClientPeerInfo e = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8083
        ..chokedFromMe = TorrentClientPeerInfo.STATE_NONE
        ..downloadedBytesFromMe = 104
        ..isClose = false;
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addPeerInfo(a);
        infos.addPeerInfo(b);
        infos.addPeerInfo(c);
        TorrentClientChokeTest test = new TorrentClientChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchoke(infos, 1, 3);
        unit.expect(r.length, 0);
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addPeerInfo(a);
        infos.addPeerInfo(b);
        infos.addPeerInfo(c);
        infos.addPeerInfo(d);
        TorrentClientChokeTest test = new TorrentClientChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchoke(infos, 1, 3);
        unit.expect(r.length, 1);
        unit.expect(true, r.contains(a));
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addPeerInfo(a);
        infos.addPeerInfo(b);
        infos.addPeerInfo(c);
        infos.addPeerInfo(e);
        TorrentClientChokeTest test = new TorrentClientChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchoke(infos, 1, 3);
        unit.expect(r.length, 1);
        unit.expect(true, r.contains(a));
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addPeerInfo(a);
        infos.addPeerInfo(b);
        infos.addPeerInfo(c);
        infos.addPeerInfo(d);
        TorrentClientChokeTest test = new TorrentClientChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchoke(infos, 2, 3);
        unit.expect(r.length, 1);
        unit.expect(true, r.contains(a));
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addPeerInfo(a);
        infos.addPeerInfo(b);
        infos.addPeerInfo(c);
        infos.addPeerInfo(d);
        infos.addPeerInfo(e);
        TorrentClientChokeTest test = new TorrentClientChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchoke(infos, 2, 3);
        unit.expect(r.length, 2);
        unit.expect(true, r.contains(a));
        unit.expect(true, r.contains(b));
      }
    });
    
    //
    //
    unit.test("extractUnchokePeerFromChoke", () {
      TorrentClientPeerInfo a = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8081
        ..chokedFromMe = TorrentClientPeerInfo.STATE_ON
        ..downloadedBytesFromMe = 100
        ..interestedToMe = TorrentClientPeerInfo.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo b = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8082
        ..chokedFromMe = TorrentClientPeerInfo.STATE_ON
        ..downloadedBytesFromMe = 101
        ..interestedToMe = TorrentClientPeerInfo.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo c = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8083
        ..chokedFromMe = TorrentClientPeerInfo.STATE_ON
        ..downloadedBytesFromMe = 102
        ..interestedToMe = TorrentClientPeerInfo.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo d = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8083
        ..chokedFromMe = TorrentClientPeerInfo.STATE_ON
        ..downloadedBytesFromMe = 103
        ..interestedToMe = TorrentClientPeerInfo.STATE_OFF
        ..isClose = false;
      TorrentClientPeerInfo e = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8083
        ..chokedFromMe = TorrentClientPeerInfo.STATE_NONE
        ..downloadedBytesFromMe = 104
        ..interestedToMe = TorrentClientPeerInfo.STATE_OFF
        ..isClose = false;
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addPeerInfo(d);
        infos.addPeerInfo(e);
        infos.addPeerInfo(a);
        infos.addPeerInfo(b);

        TorrentClientChokeTest test = new TorrentClientChokeTest();
        List<TorrentClientPeerInfo> r = test.extractUnchokePeerFromChoke(infos, 2);
        unit.expect(r.length, 2);
        unit.expect(r.contains(a), true);
        unit.expect(r.contains(b), true);
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addPeerInfo(d);
        infos.addPeerInfo(e);
        infos.addPeerInfo(a);
        infos.addPeerInfo(b);

        TorrentClientChokeTest test = new TorrentClientChokeTest();
        List<TorrentClientPeerInfo> r = test.extractUnchokePeerFromChoke(infos, 3);
        unit.expect(r.length, 3);
        unit.expect(r.contains(a), true);
        unit.expect(r.contains(b), true);
      }
    });
    
    
    //
    //
    unit.test("extractChoke", () {
      TorrentClientPeerInfo a = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8081
        ..chokedFromMe = TorrentClientPeerInfo.STATE_OFF
        ..downloadedBytesFromMe = 100
        ..interestedToMe = TorrentClientPeerInfo.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo b = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8082
        ..chokedFromMe = TorrentClientPeerInfo.STATE_OFF
        ..downloadedBytesFromMe = 101
        ..interestedToMe = TorrentClientPeerInfo.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo c = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8083
        ..chokedFromMe = TorrentClientPeerInfo.STATE_OFF
        ..downloadedBytesFromMe = 102
        ..interestedToMe = TorrentClientPeerInfo.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo d = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8084
        ..chokedFromMe = TorrentClientPeerInfo.STATE_ON
        ..downloadedBytesFromMe = 103
        ..interestedToMe = TorrentClientPeerInfo.STATE_OFF
        ..isClose = false;
      TorrentClientPeerInfo e = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..port = 8085
        ..chokedFromMe = TorrentClientPeerInfo.STATE_NONE
        ..downloadedBytesFromMe = 104
        ..interestedToMe = TorrentClientPeerInfo.STATE_OFF
        ..isClose = false;
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addPeerInfo(a);
        infos.addPeerInfo(b);
        infos.addPeerInfo(c);
        infos.addPeerInfo(d);
        infos.addPeerInfo(e);

        TorrentClientChokeTest test = new TorrentClientChokeTest();
        TorrentAIChokeTestResult r = test.extractChokeAndUnchoke(infos, 3, 1);
        unit.expect(r.choke.length, 2);
        unit.expect(r.unchoke.length, 1);
      }
    });
    
    unit.test("ttt", () {
      num i=0;
      c(int n, int k) {
        num a = 1;
        num b = 1;
        num c = 1;
        for(int i = n-k+1;i<=n;i++){
          a*= i;
        }
        for(int i = 1;i<=k;i++){
          b*= i;
        }
        return a/b;
      }
      print("${c(1000,0)*pow(998.0/1000,1000)}");
      print("${c(1000,1)*pow(998.0/1000,999)*pow(2.0/1000,1)}");
      print("${c(1000,2)*pow(998.0/1000,998)*pow(2.0/1000,2)}");
      print("${c(1000,3)*pow(998.0/1000,997)*pow(2.0/1000,3)}");
      print("${c(1000,4)*pow(998.0/1000,996)*pow(2.0/1000,4)}");
      print("${c(1000,5)*pow(998.0/1000,995)*pow(2.0/1000,5)}");
      print("${c(1000,6)*pow(998.0/1000,994)*pow(2.0/1000,6)}");
    });
  });
}

