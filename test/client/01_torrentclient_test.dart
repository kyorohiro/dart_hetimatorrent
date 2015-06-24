import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';

import 'dart:convert';

void main() {
  unit.group("torrent file", () {
    unit.test("001 testdata/1k.txt.torrent", () {
      TorrentFileCreator cre = new TorrentFileCreator();
      cre.announce = "http://0.0.0.0:8080/announce";
      HetimaDataMemory target = new HetimaDataMemory();
      target.write(UTF8.encode("helloworld"), 0);
      return cre.createFromSingleFile(target).then((TorrentFileCreatorResult result) {
        List<int> peerId = new List.filled(20, 1);
        return TorrentClient.create(new HetiSocketBuilderChrome(), peerId, result.torrentFile,target).then((TorrentClient client) {
          
        });
      });
    });
    
  });
}
