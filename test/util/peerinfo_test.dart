library peerinfo.test;

import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';

void main() {
  unit.group('A group of tests', () {
    unit.test("peerinfo: 0-1", () {
      TorrentClientPeerInfos infos = new TorrentClientPeerInfos();
      TorrentClientPeerInfo a = new TorrentClientPeerInfoEmpty()
      ..ip="0.0.0.0"
      ..acceptablePort=8081;
      TorrentClientPeerInfo b = new TorrentClientPeerInfoEmpty()
      ..ip="0.0.0.0"
      ..acceptablePort=8082;
      infos.addRawPeerInfo(a);
      infos.addRawPeerInfo(b);
      TorrentAIChokeTest test = new TorrentAIChokeTest();
      //test.extractChokePeerFromUnchokePeers(infos, numOfUnchoke, maxOfUnchoke)
    });
  });
}
