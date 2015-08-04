import 'dart:async';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet_chrome.dart';

void main() {
  KNode node = new KNode(new HetiSocketBuilderChrome());
  node.start().then((_) {
    String initialNodeIP = "0.0.0.0";
    int initialNodePort = 14803;
    node.addNodeFromIPAndPort(initialNodeIP, initialNodePort);

    int torrentClientAccessPort = 18080;
    KId torrentClientDownloadDataHash = new KId(new List.filled(20, 1));
    node.startSearchPeer(torrentClientDownloadDataHash, torrentClientAccessPort);
    node.onGetPeerValue.listen((KGetPeerValue v) {
      print("---onGetPeerValue ${v.ipAsString} ${v.port} ${v.infoHashAsString} ");
    });
    return new Future.delayed(new Duration(seconds: 60 * 5));
  }).then((_) {
    return node.stop();
  });
}
