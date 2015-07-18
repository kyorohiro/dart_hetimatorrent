library hetimatorrent.torrent.torrentfilehelper;

import 'dart:typed_data' as data;
import 'dart:async' as async;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;
import 'torrentfile.dart';
import '../util/bencode.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'sha1Isolate.dart';
import 'torrentpiecehashcreator.dart';

class TorrentFileCreator {
  String announce = "http://127.0.0.1:6969";
  String name = "name";
  int piececLength = 16 * 1024;

  async.Future<TorrentFileCreatorResult> createFromSingleFile(hetima.HetimaData target, {threadNum: 1, cacheSize: 0, cacheNum: 3, Function progress: null,isopath:null}) {
    async.Completer<TorrentFileCreatorResult> ret = new async.Completer();
    TorrentPieceHashCreator helper = new TorrentPieceHashCreator();

    target.getLength().then((int targetLength) {
      helper
          .createPieceHash(target, piececLength, threadNum: threadNum, cacheSize: cacheSize, cacheNum: cacheNum, progress: progress,isopath:isopath)
          .then((CreatePieceHashResult r) {
        Map file = {};
        Map info = {};
        file[TorrentFile.KEY_ANNOUNCE] = announce;
        file[TorrentFile.KEY_INFO] = info;
        info[TorrentFile.KEY_NAME] = name;
        info[TorrentFile.KEY_PIECE_LENGTH] = piececLength;
        info[TorrentFile.KEY_LENGTH] = targetLength;
        info[TorrentFile.KEY_PIECES] = r.pieceBuffer.toUint8List();
        TorrentFileCreatorResult result = new TorrentFileCreatorResult(TorrentFileCreatorResult.OK);
        result.torrentFile = new TorrentFile.torentmap(file);
        ret.complete(result);
      });
    });
    return ret.future;
  }

  async.Future<hetima.WriteResult> saveTorrentFile(TorrentFile target, hetima.HetimaData output) {
    async.Completer<hetima.WriteResult> c = new async.Completer();
    data.Uint8List buffer = Bencode.encode(target.mMetadata);
    output.write(buffer, 0).then((hetima.WriteResult ret) {
      c.complete(ret);
    });
    return c.future;
  }
}

class TorrentFileCreatorResult {
  static final OK = 1;
  static final NG = -1;
  int status = NG;
  TorrentFile torrentFile = null;
  TorrentFileCreatorResult(int nextStatus) {
    status = nextStatus;
  }
}

class TorrentInfoHashCreator {
  async.Future<List<int>> createInfoHash(TorrentFile file) {
    async.Completer<Object> compleator = new async.Completer();
    Object o = file.mMetadata[TorrentFile.KEY_INFO];
    if (o is data.Uint8List) {
      print("## 1");
    } else {
      print("## 2");
    }
    data.Uint8List list = Bencode.encode(file.mMetadata[TorrentFile.KEY_INFO]);
    crypto.SHA1 sha1 = new crypto.SHA1();
    sha1.add(list.toList());
    compleator.complete(sha1.close());
    return compleator.future;
  }
}

