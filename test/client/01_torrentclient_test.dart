import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';

import 'dart:convert';
import 'dart:async';

Future startTorrent(TorrentFile torrentFile, List<int> peerId, String address, int port) {
  return new Future(() {
    HetimaDataMemory target = new HetimaDataMemory();
    List<int> peerId = new List.filled(20, 1);
    return TorrentClient
        .create(new HetiSocketBuilderChrome(), peerId, torrentFile, target)
        .then((TorrentClient client) {
      client.localAddress = address;
      client.port = port;
      client.start().then((_) {
        
      });
    });
  });
}

Future<TorrentFile> createTorrentFile(List<int> data, String announce) {
  return new Future(() {
    TorrentFileCreator cre = new TorrentFileCreator();
    cre.announce = "http://0.0.0.0:8080/announce";
    HetimaDataMemory target = new HetimaDataMemory();
    target.write(UTF8.encode("helloworld"), 0);

    return cre
        .createFromSingleFile(target)
        .then((TorrentFileCreatorResult result) {
      return result.torrentFile;
    });
  });
}


Future startTracker(String address, int port) {
  return new Future(() {
    TrackerServer server = new TrackerServer(new HetiSocketBuilderChrome());
    server.address = address;
    server.port = port;
    return server.start().then((StartResult result) {
      
    });
  });
}


void main() {
  unit.group("torrent file", () {
    unit.test("001 testdata/1k.txt.torrent", () {
      String announce = "http://0.0.0.0:8080/announce";
      List<int> data = UTF8.encode("hello world");

      return createTorrentFile(data, announce).then((TorrentFile torrentFile) {
        List<int> peerId = new List.filled(20, 1);
        return startTorrent(torrentFile, peerId, "0.0.0.0", 18081);
      }).then((_){
        return startTorrent(torrentFile, peerId, "0.0.0.0", 18082);
      });
      HetimaDataMemory target = new HetimaDataMemory();
      target.write(UTF8.encode("helloworld"), 0);

      });
    });
  });
}
