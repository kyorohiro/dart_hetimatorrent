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

class TorrentFileCreator {
  String announce = "http://127.0.0.1:6969";
  String name = "name";
  int piececLength = 16 * 1024;

  async.Future<TorrentFileCreatorResult> createFromSingleFile(hetima.HetimaData target, {concurrency: false, threadNum: 2, cache: true, cacheSize: 1024, cacheNum: 3, Function progress: null}) {
    async.Completer<TorrentFileCreatorResult> ret = new async.Completer();
    TorrentPieceHashCreator helper = new TorrentPieceHashCreator();
    target.getLength().then((int targetLength) {
      helper
          .createPieceHash(target, piececLength, concurrency: concurrency, threadNum: threadNum, cache: cache, cacheSize: cacheSize, cacheNum: cacheNum, progress: progress)
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

class TorrentPieceHashCreator {
  int __timeS = 0;
  int __timeE = 0;

  async.Future<CreatePieceHashResult> createPieceHash(hetima.HetimaData file, int pieceLength,
      {concurrency: false, threadNum: 2, cache: true, cacheSize: 1024, cacheNum: 3, Function progress: null, isopath: "sha1Isolate.dart"}) {
    async.Completer<CreatePieceHashResult> compleater = new async.Completer();
    CreatePieceHashResult result = new CreatePieceHashResult();
    result.pieceLength = pieceLength;
    __timeS = new DateTime.now().millisecondsSinceEpoch;
    new async.Future(() {
      if (cache == true) {
        return hetima.HetimaDataCache.createWithReuseCashData(file, cacheSize: cacheSize, cacheNum: cacheNum).then((hetima.HetimaDataCache c) {
          result.targetFile = c;
        });
      } else {
        return new async.Future(() {
          result.targetFile = file;
        });
      }
    }).then((_) {
      // result._tmpStart = 500000*1000;
      if (concurrency == true) {
        _createPieceHashConcurrency(compleater, result, progress: progress, numOfIso: threadNum, isopath: isopath);
      } else {
        _createPieceHash(compleater, result, progress: progress);
      }
    });
    return compleater.future;
  }

  void _createPieceHashConcurrency(async.Completer<CreatePieceHashResult> compleater, CreatePieceHashResult result, {Function progress: null, numOfIso: 3, isopath: "sha1Isolate.dart"}) {

    // int timeZ = new DateTime.now().millisecond;
    SHA1Iso s = new SHA1Iso(numOfIso);
    int id = 0;

    List<int> startList = [];
    List<int> endList = [];

    innerCreatePiece(int length, int i) {
      int start = startList[i];
      int end = endList[i];
      // int timeA = new DateTime.now().millisecond;
      result.targetFile.read(start, end - start).then((hetima.ReadResult e) {
        if (++id >= numOfIso) {
          id = 0;
        }
        int begine = 20 * start ~/ result.pieceLength;
        s.requestSingleWait(e.buffer, id).then((RequestSingleWaitReturn v) {
          v.v.then((List<List<int>> dd) {
            if (progress != null) {
              progress(end);
            }
            result.addWithStart(begine, dd[0]);
         //   print("WWW${result.pieceBuffer.size()} == ${20*length~/result.pieceLength})");
            if (result.pieceBuffer.size() == 20 * startList.length) {
              __timeE = new DateTime.now().millisecondsSinceEpoch;
              print("[time]:${__timeE-__timeS}");
              if (result.cash.length != 0) {
                print("############ERROR ${result.cash.length} :: ${end} == ${length} ${result.cash[0]}");
              } else {
                compleater.complete(result);
              }
            }
          });
          if (end != length) {
            innerCreatePiece(length, i+1);
          }
        });
      });
    }
    result.targetFile.getLength().then((int length) {
      s.init(path: isopath).then((_) {
        List<List<int>> ret = _calcStartEnd(length, result.pieceLength);
        startList = ret[0];
        endList = ret[1];
        innerCreatePiece(length, 0);
      });
    });
  }

  List<List<int>> _calcStartEnd(int fileLength,int pieceLength) {
    int start = 0;
    int end = 0;
    List<List<int>> ret = [[],[]];
    while (true) {
      start = end;
      end = start + pieceLength;
      if (end > fileLength) {
        end = fileLength;
      }
      ret[0].add(start);
      ret[1].add(end);
      if (end >= fileLength) {
        break;
      }
    }
    return ret;
  }

  void _createPieceHash(async.Completer<CreatePieceHashResult> compleater, CreatePieceHashResult result, {Function progress: null}) {
    List<int> _tmp = new List(result.pieceLength);
    List<int> startList = [];
    List<int> endList = [];

    
    innerCreatePiece(int length, int i) {
      // int timeZ = new DateTime.now().millisecondsSinceEpoch;
      int start = startList[i];
      int end = endList[i];

      if (end > length) {
        end = length;
      }
      //  int timeA = new DateTime.now().millisecondsSinceEpoch;
      result.targetFile.read(start, end - start, tmp: _tmp).then((hetima.ReadResult e) {
        //   int timeB = new DateTime.now().millisecondsSinceEpoch;
        crypto.SHA1 sha1 = new crypto.SHA1();
        if (e.length == e.buffer.length) {
          sha1.add(e.buffer);
        } else {
          sha1.add(e.buffer.sublist(0, e.length));
        }
        result.add(sha1.close());
        // int timeC = new DateTime.now().millisecondsSinceEpoch;
        //   print("time:${timeA-timeZ} ${timeB-timeA} ${timeC-timeB}");

        if (progress != null) {
          progress(end);
        }

        if (end == length) {
          __timeE = new DateTime.now().millisecondsSinceEpoch;
          print("[time]:${__timeE-__timeS}");
          compleater.complete(result);
        } else {
          new async.Future.delayed(new Duration(microseconds: 10), () {
            innerCreatePiece(length, i+1);
          });
        }
      });
    }
    result.targetFile.getLength().then((int length) {
      List<List<int>> ret = _calcStartEnd(length, result.pieceLength);
      startList = ret[0];
      endList = ret[1];
      innerCreatePiece(length, 0);
    });
  }
}

class CreatePieceHashResult {
  int pieceLength = 0;
  hetima.ArrayBuilder pieceBuffer = new hetima.ArrayBuilder();
  hetima.HetimaData targetFile = null;

  List cash = [];

  void add(List<int> data) {
    pieceBuffer.appendIntList(data, 0, data.length);
    updateCash();
  }

  void updateCash() {
    int l = cash.length;
    for (int i = 0; i < l; i++) {
      for (int j = 0; j < cash.length; j++) {
        if (pieceBuffer.size() == cash[j]["s"]) {
          List<int> d = cash.removeAt(j)["v"];
          pieceBuffer.appendIntList(d, 0, d.length);
          break;
        }
      }
    }
  }

  void addWithStart(int start, List<int> data) {
    if (pieceBuffer.size() == start) {
      add(data);
    } else {
     // print("${pieceBuffer.size()} == ${start}");
      cash.add({"s": start, "v": data});
    }
  }
}
