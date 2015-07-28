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
  bool useDHT = false;
  HetimaData _seedfile = null;
  HetimaData get seedfile => _seedfile;
  HetimaData _torrentfile = null;
  HetimaData get torrentfile => _torrentfile;
  HetimaData _bitfieldfile = null;
  HetimaData get bitfieldfile => _bitfieldfile;
  TorrentFile _metadata = null;
  TorrentFile get metadata => _metadata;

  static int clientModeId = 0;
  ClientModel(String key, TorrentFile metadata) {
    this._seedfile = new HetimaDataFS("${key}.cont", erace: false);
    this._torrentfile = new HetimaDataFS("${key}.torrent", erace: true);
    this._bitfieldfile = new HetimaDataFS("${key}.bitfield", erace: false);
    this._metadata = metadata;

    HetimaDataFS.getFiles(persistent: false).then((List<String> files) {
      for (String n in files) {
        if (n == "${key}.cont") {
          return null;
        }
      }
      return this._seedfile.write([], 0);
    }).then((_) {
      return this._torrentfile.write(Bencode.encode(this._metadata.mMetadata), 0);
    }).catchError((e) {
      print("todo error");
    });
  }

  Future<int> getCurrentProgress() {
    return new Future(() {
      if (_engine != null && _engine.isGo) {
        return _engine.torrentClient.targetBlock.rawHead.numOfOn(true);
      } else {
        return _bitfieldfile.getLength().then((int len) {
          return _bitfieldfile.read(0, len).then((ReadResult result) {
            Bitfield b = new Bitfield(Bitfield.calcbitSize(_metadata.info.pieces.length), clearIsOne: false);
            b.writeBytes(result.buffer);
            return b.numOfOn(true)*_metadata.info.piece_length;
          });
        });
      }
    });
  }
  Future<SeederModelStartResult> startEngine(TorrentFile torrentFile, Function onProgress) {
    return this._bitfieldfile.getLength().then((int length) {
      return this._bitfieldfile.read(0, length);
    }).then((ReadResult re) {
      return TorrentEngine
          .createTorrentEngine(new HetiSocketBuilderChrome(), torrentFile, seedfile,
              globalPort: globalPort, localPort: localPort, localIp: localIp,
              globalIp: globalIp, useUpnp: useUpnp, useDht: false,appid: "hetimatorrentclient${clientModeId++}",bitfield:re.buffer)
          .then((TorrentEngine engine) {
        _engine = engine;
        _engine.onProgress.listen((TorrentEngineAIProgress info) {
          _bitfieldfile.write(_engine.torrentClient.targetBlock.rawHead.getBinary(), 0).catchError((e) {
            ;
          });
          onProgress(info.downloadSize, info.fileSize, info);
        });
        return _engine.start(usePortMap: useUpnp).then((_) {
          this.localIp = _engine.localIp;
          this.globalPort = _engine.globalPort;
          this.localPort = _engine.localPort;
          this.globalIp = _engine.globalIp;
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
