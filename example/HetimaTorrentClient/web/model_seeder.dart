library app.mainview.model.seeder;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class SeederModel {
  TorrentEngine _engine = null;

  String globalIp = "0.0.0.0";
  String localIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
  bool useUpnp = false;

  Future<SeederModelStartResult> startEngine(TorrentFile torrentFile, HetimaData seed) {
    return TorrentEngine.createTorrentEngine(
        new HetiSocketBuilderChrome(), torrentFile, seed
        ,globalPort:globalPort,localPort:localPort,localIp:localIp,globalIp:globalIp, useUpnp:useUpnp,appid: "hetimatorrentclient").then((TorrentEngine engine) {
      _engine = engine;
      return _engine.go(usePortMap:useUpnp).then((_){
        this.localIp = _engine.localIp;
        this.globalPort = _engine.globalPort;
        this.localPort = _engine.localPort;
        this.globalIp = _engine.globalIp;
        return new SeederModelStartResult()..localIp=localIp..localPort=localPort..globalPort=globalPort..globalIp=globalIp;
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
  String globalIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
}