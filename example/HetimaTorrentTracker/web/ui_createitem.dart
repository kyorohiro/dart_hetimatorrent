library app.mainview.createitem;

import 'dart:html' as html;
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'model_tracker.dart';


class CreateItem {
  html.InputElement inputFile = html.querySelector("#create-fileinput");
  html.InputElement inputAnnounce = html.querySelector("#create-announce");
  html.InputElement inputPieceLength = html.querySelector("#create-piece-length");
  html.AnchorElement inputLink = html.querySelector("#create-link");

  html.InputElement inputCacheSize = html.querySelector("#create-cache-size");
  html.InputElement inputThreadNum = html.querySelector("#create-thread-num");
  html.SpanElement outputProgress = html.querySelector("#create-progress");
  
  html.File _rawFile = null;
  Dialog dialog = null;


  init(TrackerModel model, Map<String, TorrentFile> managedTorrentFile, Tab tab, Dialog d) {
    dialog = d;
    inputFile.onChange.listen((html.Event e) {
      print("==");
      inputLink.style.display = "none";
      if (inputFile.files.length > 0) {

        html.File n = inputFile.files[0];
        TorrentFileCreator cre = new TorrentFileCreator();
        cre.announce = inputAnnounce.value;
        cre.piececLength = int.parse(inputPieceLength.value) * 1024;
        
        int cashSize = int.parse(inputCacheSize.value)*1024;
        if(cashSize > 0 && cashSize < cre.piececLength) {
          cashSize = cashSize*2;
        }
        int threadNum = int.parse(inputThreadNum.value);
        onPro(int v) {
          outputProgress.setInnerHtml("${v} / ${n.size}");
        }
        return cre.createFromSingleFile(new HetimaDataBlob(n),
             threadNum:threadNum-1, cacheSize: cashSize, cacheNum: 3, progress:onPro,isopath:"subiso.dart").then((TorrentFileCreatorResult r) {
          List<int> buffer = Bencode.encode(r.torrentFile.mMetadata);
          HetimaDataFS fs = new HetimaDataFS("a.torrent");
          return fs.write(buffer, 0).then((WriteResult r) {
            return fs.truncate(buffer.length).then((_) {
              return fs.getEntry().then((html.Entry e) {
                inputLink.href = e.toUrl();
                inputLink.style.display = "block";
                (e as html.FileEntry).file().then((html.File f) {
                  _rawFile = f;
                });
              });
            });
          });
        });
      }
    });
    inputLink.onClick.listen((_) {
      print("click");
      saveFile();
    });
  }

  void saveFile() {
    String choseFile = "";
    try {
      chrome.fileSystem.chooseEntry(new chrome.ChooseEntryOptions(type: chrome.ChooseEntryType.SAVE_FILE, suggestedName: "a.torrent")).then((chrome.ChooseEntryResult chooseEntryResult) {
        choseFile = chooseEntryResult.entry.toUrl();
        chrome.fileSystem.getWritableEntry(chooseEntryResult.entry).then((chrome.ChromeFileEntry copyTo) {
          HetimaDataBlob copyFrom = new HetimaDataBlob(_rawFile);
          copyFrom.getLength().then((int length) {
            copyFrom.read(0, length).then((ReadResult readResult) {
              chrome.ArrayBuffer buffer = new chrome.ArrayBuffer.fromBytes(readResult.buffer.toList());
//              copyTo.remove().then((e){
              copyTo.writeBytes(buffer);
//              });
            });
          });
        });
      });
    } catch (e) {
      dialog.show("failed to copy");
    }
  }
}
