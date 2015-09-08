library app.mainview.model.seeder;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimafile/hetimafile_cl.dart';
import 'model_main.dart';

class ClientModel {
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
    return _metadata.createInfoSha1().then((List<int> infoHash) {
      return AppModel.getInstance().get().then((TorrentEngine _engine) {
        if (_engine != null && _engine.isStart) {
          return _engine.getTorrent(infoHash).torrentClient.targetBlock.rawHead.numOfOn(true);
        } else {
          return _bitfieldfile.getLength().then((int len) {
            return _bitfieldfile.read(0, len).then((ReadResult result) {
              Bitfield b = new Bitfield(Bitfield.calcbitSize(_metadata.info.pieces.length,_metadata.info.files.dataSize), clearIsOne: false);
              b.writeBytes(result.buffer);
              return b.numOfOn(true) * _metadata.info.piece_length;
            });
          });
        }
      });
    });
  }

  Future<SeederModelStartResult> startEngine(TorrentFile torrentFile, Function onProgress) {
    return this._bitfieldfile.getLength().then((int length) {
      return this._bitfieldfile.read(0, length);
    }).then((ReadResult re) {
      return AppModel.getInstance().start().then((TorrentEngine engine) {
        return engine.addTorrent(torrentFile, seedfile, bitfield: re.buffer).then((TorrentEngineTorrent t) {
          t.onProgress.listen((TorrentEngineProgress info) {
            _bitfieldfile.write(t.torrentClient.targetBlock.rawHead.getBinary(), 0).catchError((e) {
              ;
            });
            onProgress(info.downloadSize, info.fileSize, info);
          });
          t.startTorrent(engine);
          return new SeederModelStartResult()
            ..localIp = engine.localIp
            ..localPort = engine.localPort
            ..globalPort = engine.globalPort
            ..globalIp = engine.globalIp;
        });
      });
    });
  }

  Future stopEngine() {
    return _metadata.createInfoSha1().then((List<int> infoHash) {
      return AppModel.getInstance().get().then((TorrentEngine engine) {
        TorrentEngineTorrent t = engine.getTorrent(infoHash);
        if(t == null) {
          return {};
        }
        return t.stopTorrent().then((_){
          engine.removeTorrent(engine.getTorrent(infoHash));
          if(engine.numOfTorrent == 0) {
            return engine.stop();
          }
        });
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
