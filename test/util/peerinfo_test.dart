library peerinfo.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';

void main() {
  unit.group('A group of tests', () {
    unit.test("peerinfo: 0-1", () {
      TorrentClientPeerInfo a = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8081
        ..chokedFromMe = TorrentClientFront.STATE_OFF
        ..downloadedBytesFromMe = 100
        ..isClose = false;
      TorrentClientPeerInfo b = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8082
        ..chokedFromMe = TorrentClientFront.STATE_OFF
        ..downloadedBytesFromMe = 101
        ..isClose = false;
      TorrentClientPeerInfo c = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8083
        ..chokedFromMe = TorrentClientFront.STATE_OFF
        ..downloadedBytesFromMe = 102
        ..isClose = false;
      TorrentClientPeerInfo d = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8083
        ..chokedFromMe = TorrentClientFront.STATE_OFF
        ..downloadedBytesFromMe = 103
        ..isClose = false;
      TorrentClientPeerInfo e = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8083
        ..chokedFromMe = TorrentClientFront.STATE_NONE
        ..downloadedBytesFromMe = 104
        ..isClose = false;
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addRawPeerInfo(a);
        infos.addRawPeerInfo(b);
        infos.addRawPeerInfo(c);
        TorrentAIChokeTest test = new TorrentAIChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchokePeers(infos, 1, 3);
        unit.expect(r.length, 0);
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addRawPeerInfo(a);
        infos.addRawPeerInfo(b);
        infos.addRawPeerInfo(c);
        infos.addRawPeerInfo(d);
        TorrentAIChokeTest test = new TorrentAIChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchokePeers(infos, 1, 3);
        unit.expect(r.length, 1);
        unit.expect(true, r.contains(a));
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addRawPeerInfo(a);
        infos.addRawPeerInfo(b);
        infos.addRawPeerInfo(c);
        infos.addRawPeerInfo(e);
        TorrentAIChokeTest test = new TorrentAIChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchokePeers(infos, 1, 3);
        unit.expect(r.length, 1);
        unit.expect(true, r.contains(a));
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addRawPeerInfo(a);
        infos.addRawPeerInfo(b);
        infos.addRawPeerInfo(c);
        infos.addRawPeerInfo(d);
        TorrentAIChokeTest test = new TorrentAIChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchokePeers(infos, 2, 3);
        unit.expect(r.length, 1);
        unit.expect(true, r.contains(a));
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addRawPeerInfo(a);
        infos.addRawPeerInfo(b);
        infos.addRawPeerInfo(c);
        infos.addRawPeerInfo(d);
        infos.addRawPeerInfo(e);
        TorrentAIChokeTest test = new TorrentAIChokeTest();
        List<TorrentClientPeerInfo> r = test.extractChokePeerFromUnchokePeers(infos, 2, 3);
        unit.expect(r.length, 2);
        unit.expect(true, r.contains(a));
        unit.expect(true, r.contains(b));
      }
    });
    
    //
    //
    unit.test("peerinfo: 0-1", () {
      TorrentClientPeerInfo a = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8081
        ..chokedFromMe = TorrentClientFront.STATE_ON
        ..downloadedBytesFromMe = 100
        ..interestedToMe = TorrentClientFront.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo b = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8082
        ..chokedFromMe = TorrentClientFront.STATE_ON
        ..downloadedBytesFromMe = 101
        ..interestedToMe = TorrentClientFront.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo c = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8083
        ..chokedFromMe = TorrentClientFront.STATE_ON
        ..downloadedBytesFromMe = 102
        ..interestedToMe = TorrentClientFront.STATE_ON
        ..isClose = false;
      TorrentClientPeerInfo d = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8083
        ..chokedFromMe = TorrentClientFront.STATE_ON
        ..downloadedBytesFromMe = 103
        ..interestedToMe = TorrentClientFront.STATE_OFF
        ..isClose = false;
      TorrentClientPeerInfo e = new TorrentClientPeerInfoEmpty()
        ..ip = "0.0.0.0"
        ..acceptablePort = 8083
        ..chokedFromMe = TorrentClientFront.STATE_NONE
        ..downloadedBytesFromMe = 104
        ..interestedToMe = TorrentClientFront.STATE_OFF
        ..isClose = false;
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addRawPeerInfo(d);
        infos.addRawPeerInfo(e);
        infos.addRawPeerInfo(a);
        infos.addRawPeerInfo(b);

        TorrentAIChokeTest test = new TorrentAIChokeTest();
        List<TorrentClientPeerInfo> r = test.extractUnchokePeerFromChoke(infos, 2);
        unit.expect(r.length, 2);
        unit.expect(r.contains(a), true);
        unit.expect(r.contains(b), true);
      }
      {
        TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
        infos.addRawPeerInfo(d);
        infos.addRawPeerInfo(e);
        infos.addRawPeerInfo(a);
        infos.addRawPeerInfo(b);

        TorrentAIChokeTest test = new TorrentAIChokeTest();
        List<TorrentClientPeerInfo> r = test.extractUnchokePeerFromChoke(infos, 3);
        unit.expect(r.length, 3);
        unit.expect(r.contains(a), true);
        unit.expect(r.contains(b), true);
      }
    });
  });
}
