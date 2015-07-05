library app.mainview.model.seeder;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class SeederModel {
  TorrentEngine _engine = null;

  String localIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
  bool useUpnp = false;

  Future startEngine(TorrentFile torrentFile, HetimaData seed, bool haveAllData) {
    return TorrentEngine.createTorrentEngine(new HetiSocketBuilderChrome(), torrentFile, seed, haveAllData: haveAllData, aiIsOn: true).then((TorrentEngine engine) {
      _engine = engine;
      return _engine.go();
    });
  }

  Future stopEngine() {
    return new Future(() {
      if (_engine != null) {
        return _engine.stop();
      } else {
        return new Future(() {});
      }
    });
  }
}
