import 'package:unittest/unittest.dart' as unit;
import 'package:hetimatorrent/hetimatorrent.dart' as hetima;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimacore/hetimacore_cl.dart' as hetima_cl;
import 'dart:typed_data' as type;
import 'dart:convert' as convert;
import 'dart:html' as html;
import 'dart:async' as async;

void main() {
  unit.group("torrent file", () {
    unit.test("001 testdata/1k.txt.torrent", () {
      hetima_cl.HetimaDataGet file = new hetima_cl.HetimaDataGet("testdata/1k.txt.torrent");
      return file.getLength().then((int length) {
        return file.read(0, length);
      }).then((hetima.ReadResult result) {
        hetima.TorrentFile f = new hetima.TorrentFile.loadTorrentFileBuffer(result.buffer);
        unit.expect("http://127.0.0.1:6969/announce", f.announce);
        unit.expect("1k.txt", f.info.name);
        unit.expect(1, f.info.files.path.length);
        unit.expect("1k.txt", f.info.files.path[0].pathAsString);
        unit.expect(1024, f.info.files.path[0].fileSize);
      });
    });

    unit.test("002 testdata/1kb.torrent", () {
      hetima_cl.HetimaDataGet file = new hetima_cl.HetimaDataGet("testdata/1kb.torrent");
      return file.getLength().then((int length) {
        return file.read(0, length);
      }).then((hetima.ReadResult result) {
        hetima.TorrentFile f = new hetima.TorrentFile.loadTorrentFileBuffer(result.buffer);
        unit.expect("http://127.0.0.1:6969/announce", f.announce);
        unit.expect("1kb", f.info.name);
        unit.expect(2, f.info.files.path.length);
        unit.expect("1k_b.txt", f.info.files.path[0].pathAsString);
        unit.expect(1024, f.info.files.path[0].fileSize);
        unit.expect("1k.txt", f.info.files.path[1].pathAsString);
        unit.expect(1024, f.info.files.path[1].fileSize);
      });
    });

    unit.test("004 hetimafile get ss testdata/1kb/1k.txt", () {
      hetima_cl.HetimaDataGet file = new hetima_cl.HetimaDataGet("testdata/1kb/1k.txt");
      hetima.TorrentPieceHashCreator h = new hetima.TorrentPieceHashCreator();
      return h.createPieceHash(file, 16 * 1024).then((hetima.CreatePieceHashResult r) {
        List<int> expect = [196, 42, 125, 9, 64, 47, 78, 143, 209, 15, 188, 87, 124, 199, 203, 157, 198, 52, 62, 142];
        unit.expect(20, r.pieceBuffer.size());
        for (int i = 0; i < r.pieceBuffer.size(); i++) {
          unit.expect(expect[i], r.pieceBuffer.toList()[i]);
        }
      });
    });

    unit.test("005 hetimafile get double", () {
      hetima.TorrentPieceHashCreator h = new hetima.TorrentPieceHashCreator();
      hetima_cl.HetimaDataGet file001 = new hetima_cl.HetimaDataGet("testdata/1kb/1k_b.txt");
      hetima_cl.HetimaDataGet file002 = new hetima_cl.HetimaDataGet("testdata/1kb/1k.txt");
      return file001.getBlob().then((html.Blob b1) {
        return file002.getBlob().then((html.Blob b2) {
          hetima_cl.HetimaDataBlob file = new hetima_cl.HetimaDataBlob(new html.Blob([b1, b2]));
          return h.createPieceHash(file, 16 * 1024);
        });
      }).then((hetima.CreatePieceHashResult r) {
        List<int> expect = [149, 96, 47, 41, 153, 193, 171, 203, 165, 128, 108, 193, 118, 11, 175, 49, 229, 27, 231, 149];
        unit.expect(20, r.pieceBuffer.size());
        for (int i = 0; i < r.pieceBuffer.size(); i++) {
          unit.expect(expect[i], r.pieceBuffer.toList()[i]);
        }
      });
    });
    unit.test("006 create torrent", () {
      hetima_cl.HetimaDataGet file = new hetima_cl.HetimaDataGet("testdata/1kb/1k.txt");
      hetima.TorrentFileCreator c = new hetima.TorrentFileCreator();
      c.name = "1k.txt";
      c.announce = "http://www.example.com/tracker:6969";
      return c.createFromSingleFile(file).then((hetima.TorrentFileCreatorResult e) {
        e.torrentFile;
        List<int> expect = [196, 42, 125, 9, 64, 47, 78, 143, 209, 15, 188, 87, 124, 199, 203, 157, 198, 52, 62, 142];
        unit.expect(20, e.torrentFile.info.pieces.length);
        for (int i = 0; i < e.torrentFile.info.pieces.length; i++) {
          unit.expect(expect[i], e.torrentFile.info.pieces[i]);
        }
        unit.expect(16 * 1024, e.torrentFile.info.piece_length);
        unit.expect("http://www.example.com/tracker:6969", e.torrentFile.announce);
        unit.expect(1, e.torrentFile.info.files.numOfFiles);
        unit.expect(1024, e.torrentFile.info.files.path[0].fileSize);
        unit.expect("1k.txt", e.torrentFile.info.files.path[0].pathAsString);
      });
    });
  });

  unit.test("006 create torrent", () {
    bool testable = false;
    new async.Future.sync(() {
      hetima_cl.HetimaDataGet file = new hetima_cl.HetimaDataGet("testdata/1k.txt.torrent");
      return file.getLength().then((int length) {
        return file.read(0, length).then((hetima.ReadResult r) {
          return hetima.TorrentFile.createTorrentFileFromTorrentFile(new hetima.ArrayBuilder.fromList(r.buffer));
        }).then((hetima.TorrentFile f) {
          hetima.TorrentInfoHashCreator creator = new hetima.TorrentInfoHashCreator();
          return creator.createInfoHash(f);
        }).catchError((e) {
          print("[Z[Z]Z]= false");
        });
      });
    }).then((List<int> hash) {
      List<int> expect = [95, 198, 184, 162, 100, 99, 51, 245, 99, 157, 78, 149, 43, 155, 184, 173, 238, 18, 26, 189];
      print("[Z[Z]Z]=" + hash.toString());
      unit.expect(hash, expect);
    }).catchError((e) {
      print("[Z[Z]Z]= false");
    });
  });
}
