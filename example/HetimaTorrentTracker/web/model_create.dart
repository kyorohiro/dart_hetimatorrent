library app.mainview.model.create;

import 'dart:async';
import 'dart:html' as html;
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class CreateFileModel {
  html.File _rawFile = null;
  TorrentClient client = null;
  

  Future createFile(html.File n, String announce, int pieceLength, int cashSize, int threadNum, String name, String fileName, Function onPro) {
    TorrentFileCreator cre = new TorrentFileCreator();
    cre.announce = announce;
    cre.piececLength = pieceLength;
    cre.name = name;

    if (cashSize > 0 && cashSize < cre.piececLength) {
      cashSize = cashSize * 2;
    }
    return cre.createFromSingleFile(new HetimaDataBlob(n), threadNum: threadNum , cacheSize: cashSize, cacheNum: 3, progress: onPro, isopath: "subiso.dart").then((TorrentFileCreatorResult r) {
      List<int> buffer = Bencode.encode(r.torrentFile.mMetadata);
      HetimaDataFS fs = new HetimaDataFS(fileName);
      return fs.write(buffer, 0).then((WriteResult r) {
        return fs.truncate(buffer.length).then((_) {
          return fs.getEntry().then((html.Entry e) {
            return (e as html.FileEntry).file().then((html.File f) {
              _rawFile = f;
              return _rawFile;
            });
          });
        });
      });
    });
  }

  Future saveFile() {
    return chrome.fileSystem.chooseEntry(new chrome.ChooseEntryOptions(type: chrome.ChooseEntryType.SAVE_FILE, suggestedName: "a.torrent")).then((chrome.ChooseEntryResult chooseEntryResult) {
      return chrome.fileSystem.getWritableEntry(chooseEntryResult.entry).then((chrome.ChromeFileEntry copyTo) {
        HetimaDataBlob copyFrom = new HetimaDataBlob(_rawFile);
        return copyFrom.getLength().then((int length) {
          return copyFrom.read(0, length).then((ReadResult readResult) {
            chrome.ArrayBuffer buffer = new chrome.ArrayBuffer.fromBytes(readResult.buffer.toList());
            return copyTo.writeBytes(buffer);
          });
        });
      });
    });
  }
}
