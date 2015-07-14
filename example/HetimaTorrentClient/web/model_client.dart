library app.mainview.model.seeder;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimafile/hetimafile_cl.dart';

class ClientModel {
  TorrentEngine _engine = null;

  String globalIp = "0.0.0.0";
  String localIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
  bool useUpnp = false;
  HetimaData _seedfile = null;
  HetimaData get seedfile => _seedfile;
  HetimaData _torrentfile = null;
  HetimaData get torrentfile => _torrentfile;

  TorrentFile _metadata = null;
  TorrentFile get metadata => _metadata;

  ClientModel(String key, TorrentFile metadata) {
    this._seedfile = new HetimaDataFS("${key}.cont", erace: false);
    this._torrentfile = new HetimaDataFS("${key}.torrent", erace: true);
    this._metadata = metadata;

    HetimaDataFS.getFiles(persistent:false).then((List<String> files) {
      for(String n in files) {
       if(n == "${key}.cont") {
         return;
       }
      }
      this._seedfile.write([], 0);
    }).then((_){
      this._torrentfile.write(Bencode.encode(this._metadata.mMetadata), 0);
    }).catchError((e){
      print("todo error");
    });
  }

  Future<SeederModelStartResult> startEngine(TorrentFile torrentFile, Function onProgress) {
    _seedfile = seedfile;
    return TorrentEngine.createTorrentEngine(
        new HetiSocketBuilderChrome(), torrentFile, seedfile
        ,globalPort:globalPort, localPort:localPort, localIp:localIp
        ,globalIp:globalIp, useUpnp:useUpnp,appid: "hetimatorrentclient").then((TorrentEngine engine) {
      _engine = engine;
      _engine.onProgress.listen((TorrentEngineAIProgress info) {
        onProgress(info.downloadSize,info.fileSize);
      });
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