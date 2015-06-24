import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';

import 'dart:convert';
import 'dart:async';

class TestCaseCreator2Client1Tracker {
  TorrentFile torrentFile = null;
  TorrentClient clientA = null;
  TorrentClient clientB = null;
  TrackerServer tracker = null;

  String localAddress = "0.0.0.0";
  String announce = "http://0.0.0.0:28080/announce";
  List<int> data = UTF8.encode("helloworld");
  int clientAPort = 18081;
  int clientBPort = 18082;
  int trackerPort = 28080;

  Future<TorrentClient> _startTorrent(TorrentFile torrentFile, List<int> peerId, int port) {
    return new Future(() {
      HetimaDataMemory target = new HetimaDataMemory();
      List<int> peerId = new List.filled(20, 1);
      return TorrentClient.create(new HetiSocketBuilderChrome(), peerId, torrentFile, target).then((TorrentClient client) {
        client.localAddress = localAddress;
        client.port = port;
        return client.start().then((_) {
          return client;
        });
      });
    });
  }

  Future<TorrentFile> _createTorrentFile() {
    return new Future(() {
      TorrentFileCreator cre = new TorrentFileCreator();
      cre.announce = announce;
      HetimaDataMemory target = new HetimaDataMemory();
      target.write(data, 0);
      return cre.createFromSingleFile(target).then((TorrentFileCreatorResult result) {
        return result.torrentFile;
      });
    });
  }

  Future<TrackerServer> _startTracker(int port, TorrentFile f) {
    return new Future(() {
      TrackerServer server = new TrackerServer(new HetiSocketBuilderChrome());
      server.address = localAddress;
      server.port = port;
      server.addInfoHash(f);
      return server.start().then((StartResult result) {
        return server;
      });
    });
  }

  Future createTestEnv() {
    new Future(() {
      TrackerClient trackerClientTmp = null;
      return _createTorrentFile().then((TorrentFile _torrentFile) {
        torrentFile = _torrentFile;
        List<int> peerId = new List.filled(20, 1);
        return _startTorrent(torrentFile, peerId, clientAPort);
      }).then((TorrentClient client) {
        clientA = client;
        clientA.onReceiveEvent.listen((TorrentMessageInfo info) {
          print("info:${info.message.id}");
        });
        List<int> peerId = new List.filled(20, 2);
        return _startTorrent(torrentFile, peerId, clientBPort);
      }).then((TorrentClient client) {
        clientB = client;
        return _startTracker(trackerPort, torrentFile);
      }).then((TrackerServer server) {
        tracker = server;
        return TrackerClient.createTrackerClient(new HetiSocketBuilderChrome(), torrentFile);
      }).then((TrackerClient client) {
        trackerClientTmp = client;
        trackerClientTmp.peerport = clientAPort;
        return client.request();
      }).then((TrackerRequestResult result) {
        trackerClientTmp.peerport = clientBPort;
        return trackerClientTmp.request();
      }).then((TrackerRequestResult result) {
        for (TrackerPeerInfo info in result.response.peers) {
          clientA.putTorrentPeerInfo(info.ipAsString, info.port);
          clientB.putTorrentPeerInfo(info.ipAsString, info.port);
        }
        return null;
      });
    }).catchError((e) {
      new Future(() {
        tracker.stop();
      }).catchError((e) {});
      new Future(() {
        clientA.stop();
      }).catchError((e) {});
      new Future(() {
        clientB.stop();
      }).catchError((e) {});
      throw {};
    });
  }
}
