import 'dart:html';
import 'dart:async';

import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimacore/hetimacore.dart';

void main() {
  KNode node = new KNode(new HetiSocketBuilderChrome());
  node.start().then((_) {
    int torrentClientAccessPort = 18080;
    KId torrentClientDownloadDataHash = new KId(new List.filled(20, 1));
    node.startSearchPeer(torrentClientDownloadDataHash, torrentClientAccessPort);
    return new Future.delayed(new Duration(seconds: 60 * 5));
  }).then((_) {
    return node.stop();
  });
}
