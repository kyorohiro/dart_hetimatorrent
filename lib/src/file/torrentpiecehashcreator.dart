library hetimatorrent.torrent.torrentpiecehashcreator;

import 'dart:typed_data' as data;
import 'dart:async' as async;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;
import 'torrentfile.dart';
import '../util/bencode.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'sha1Isolate.dart';


class TorrentPieceHashCreator {
  int __timeS = 0;
  int __timeE = 0;

  async.Future<CreatePieceHashResult> createPieceHash(hetima.HetimaData file, int pieceLength,
      {threadNum: 1, cacheSize: 0, cacheNum: 3, Function progress: null, isopath: "sha1Isolate.dart"}) {
    async.Completer<CreatePieceHashResult> compleater = new async.Completer();
    CreatePieceHashResult result = new CreatePieceHashResult();
    result.pieceLength = pieceLength;
    __timeS = new DateTime.now().millisecondsSinceEpoch;
    
    bool cache = (cacheSize > 0 && cacheNum > 0);
    bool concurrency  = (threadNum > 1 && isopath!=null);
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
    List<List<int>> cash = [];
    for(int i = 0;i<numOfIso;i++) {
      cash.add(new List.filled(result.pieceLength, 0));
    }
    

    innerCreatePiece(int length, int i) {
      int start = startList[i];
      int end = endList[i];
      result.targetFile.read(start, end - start).then((hetima.ReadResult e) {
        if (++id >= numOfIso) {
          id = 0;
        }
        int begine = 20 * start ~/ result.pieceLength;
        
        List<int> v = null;
        if(e.buffer.length == result.pieceLength) {
          cash[id].setAll(0, e.buffer);
          v = cash[id];
        } else {
          v = e.buffer.toList(growable:false);
        }
        s.requestSingleWait(v, id).then((RequestSingleWaitReturn v) {
          v.v.then((List<List<int>> dd) {
            if (progress != null) {
              progress(end);
            }
            result.addWithStart(begine, dd[0]);
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
      print("---path---${isopath}");
      s.init(path: isopath).then((_) {
        List<List<int>> ret = _calcStartEnd(length, result.pieceLength);
        startList = ret[0];
        endList = ret[1];
        innerCreatePiece(length, 0);
      });
    });
  }
/*
 * 
 */
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
