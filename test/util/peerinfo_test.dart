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
    });
  });
}
