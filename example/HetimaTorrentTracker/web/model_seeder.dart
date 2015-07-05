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

  Future<SeederModelStartResult> startEngine(TorrentFile torrentFile, HetimaData seed, bool haveAllData) {
    return TorrentEngine.createTorrentEngine(
        new HetiSocketBuilderChrome(), torrentFile, seed, haveAllData: haveAllData
        ,globalPort:globalPort,localPort:localPort,useUpnp:useUpnp).then((TorrentEngine engine) {
      _engine = engine;
      return _engine.go().then((_){
        this.localIp = _engine.localIp;
        this.globalPort = _engine.globalPort;
        this.localPort = _engine.localPort;
        return new SeederModelStartResult()..localIp=localIp..localPort=localPort..globalPort=globalPort;
      });
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

class SeederModelStartResult {
  String localIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
}