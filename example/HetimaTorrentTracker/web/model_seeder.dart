library app.mainview.model.seeder;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class SeederModel {
  String globalIp = "0.0.0.0";
  String localIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
  bool useUpnp = false;
  bool useDht = false;
  static int _idBase = 0;
  int _id = 0;

  TorrentFile _currentFile = null;
  SeederModel() {
    this._id = _idBase++;
  }

  static TorrentEngine _rawengine = null;
  TorrentEngine getEngine() {
    if (_rawengine == null) {
      _rawengine = new TorrentEngine(new HetiSocketBuilderChrome(),
          appid: "hetima_tracker_seeder", globalPort: globalPort, localPort: localPort, localIp: localIp, globalIp: globalIp, useUpnp: useUpnp, useDht: useDht);
    }
    return _rawengine;
  }

  Future<TorrentEngine> startEngine_() {
    TorrentEngine engine = getEngine();
    if (engine.isStart == true) {
      return new Future(() {
        return engine;
      });
    } else {
      return engine.start().then((_) {
        return engine;
      });
    }
  }

  Future<SeederModelStartResult> startEngine(TorrentFile torrentFile, HetimaData seed, bool haveAllData) {
    _currentFile = torrentFile;
    return startEngine_().then((TorrentEngine engine) {
      return engine.addTorrent(torrentFile, seed, haveAllData:haveAllData).then((TorrentEngineTorrent t) {
        return t.startTorrent(engine).then((_) {
          this.localIp = engine.localIp;
          this.globalPort = engine.globalPort;
          this.localPort = engine.localPort;
          this.globalIp = engine.globalIp;
          return new SeederModelStartResult()
            ..localIp = localIp
            ..localPort = localPort
            ..globalPort = globalPort
            ..globalIp = globalIp;
        });
      });
    });
  }

  Future stopEngine() {
    return new Future(() {
      if (_currentFile == null) {
        return {};
      }

      TorrentEngine engine = getEngine();
      return _currentFile.createInfoSha1().then((List<int> infoHash) {
        TorrentEngineTorrent t = engine.getTorrent(infoHash);
        if (t != null) {
          return engine.getTorrent(infoHash).stopTorrent().then((_) {
            engine.removeTorrent(t);
          });
        }
      }).whenComplete(() {
        if (engine.numOfTorrent() <= 0) {
          return engine.stop();
        }
      });
    });
  }
}

class SeederModelStartResult {
  String localIp = "0.0.0.0";
  String globalIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
}
