import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';

import 'dart:convert';
import 'dart:async';

Future<TorrentClient> startTorrent(TorrentFile torrentFile, List<int> peerId, String address, int port) {
  return new Future(() {
    HetimaDataMemory target = new HetimaDataMemory();
    List<int> peerId = new List.filled(20, 1);
    return TorrentClient.create(new HetiSocketBuilderChrome(), peerId, torrentFile, target).then((TorrentClient client) {
      client.localAddress = address;
      client.port = port;
      return client.start().then((_) {
        return client;
      });
    });
  });
}

Future<TorrentFile> createTorrentFile(List<int> data, String announce) {
  return new Future(() {
    TorrentFileCreator cre = new TorrentFileCreator();
    cre.announce = "http://0.0.0.0:28080/announce";
    HetimaDataMemory target = new HetimaDataMemory();
    target.write(UTF8.encode("helloworld"), 0);

    return cre.createFromSingleFile(target).then((TorrentFileCreatorResult result) {
      return result.torrentFile;
    });
  });
}

Future<TrackerServer> startTracker(String address, int port, TorrentFile f) {
  return new Future(() {
    TrackerServer server = new TrackerServer(new HetiSocketBuilderChrome());
    server.address = address;
    server.port = port;
    server.addInfoHash(f);
    return server.start().then((StartResult result) {
      return server;
    });
  });
}

void main() {
  unit.group("torrent file", () {
    unit.test("001 testdata/1k.txt.torrent", () {
      TorrentFile torrentFile = null;
      TorrentClient clientA = null;
      TorrentClient clientB = null;
      TrackerServer tracker = null;
      new Future(() {
        String announce = "http://0.0.0.0:28080/announce";
        List<int> data = UTF8.encode("hello world");
        return createTorrentFile(data, announce).then((TorrentFile _torrentFile) {
          print("----0000----");
          torrentFile = _torrentFile;
          List<int> peerId = new List.filled(20, 1);
          return startTorrent(torrentFile, peerId, "0.0.0.0", 18081);
        }).then((TorrentClient client) {
          print("----0001----");
          clientA = client;
          clientA.onReceiveEvent.listen((TorrentMessageInfo info) {
            print("info:${info.message.id}");
          });
          List<int> peerId = new List.filled(20, 2);
          return startTorrent(torrentFile, peerId, "0.0.0.0", 18082);
        }).then((TorrentClient client) {
          print("----0002----");
          clientB = client;
          return startTracker("0.0.0.0", 28080, torrentFile);
        }).then((TrackerServer server) {
          tracker = server;
          return TrackerClient.createTrackerClient(new HetiSocketBuilderChrome(), torrentFile).then((TrackerClient client) {
            client.peerport = 18081;
            return client.request().then((TrackerRequestResult result) {
              print("----0003----");
              for (TrackerPeerInfo info in result.response.peers) {
                clientA.putTorrentPeerInfo(info.ipAsString, info.port);
              }
              client.peerport = 18082;
              return client.request();
            }).then((TrackerRequestResult result) {
              print("----0004----");
              for (TrackerPeerInfo info in result.response.peers) {
                clientB.putTorrentPeerInfo(info.ipAsString, info.port);
              }
              return null;
            });
          });
        }).then((_){
          List<TorrentClientPeerInfo> infos = clientB.getPeerInfoFromXx((TorrentClientPeerInfo info) {
            if(info.port == 18081) {
              return true;
            }
          });
          return clientB.connect(infos[0]);
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
        new Future((){tracker.stop();}).catchError((e){});
        new Future((){clientA.stop();}).catchError((e){});
        new Future((){clientB.stop();}).catchError((e){});
      });//
    });
  });
}
