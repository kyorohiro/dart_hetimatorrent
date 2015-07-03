library app.mainview.createitem;

import 'dart:html' as html;
import 'dart:async';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'model_tracker.dart';
import 'model_create.dart';

class CreateItem {
  html.InputElement inputFile = html.querySelector("#create-fileinput");
  html.InputElement inputAnnounce = html.querySelector("#create-announce");
  html.InputElement inputPieceLength = html.querySelector("#create-piece-length");
  html.AnchorElement inputLink = html.querySelector("#create-link");

  html.InputElement inputCacheSize = html.querySelector("#create-cache-size");
  html.InputElement inputThreadNum = html.querySelector("#create-thread-num");
  html.SpanElement outputProgress = html.querySelector("#create-progress");
  html.InputElement inputCreateName = html.querySelector("#create-name");
  Dialog dialog = null;
  CreateFileModel createFileModel = new CreateFileModel();

  init(TrackerModel model, Map<String, TorrentFile> managedTorrentFile, Tab tab, Dialog d) {
    dialog = d;
    inputFile.onChange.listen((html.Event e) {
      print("==");
      new Future(() {
        inputLink.style.display = "none";
        if (inputFile.files.length > 0) {
          html.File n = inputFile.files[0];
          TorrentFileCreator cre = new TorrentFileCreator();
          String announce = inputAnnounce.value;
          int pieceLength = int.parse(inputPieceLength.value) * 1024;

          int cashSize = int.parse(inputCacheSize.value) * 1024;
          if (cashSize > 0 && cashSize < cre.piececLength) {
            cashSize = cashSize * 2;
          }
          int threadNum = int.parse(inputThreadNum.value);
          onPro(int v) {
            outputProgress.setInnerHtml("${v} / ${n.size}");
          }
          createFileModel.createFile(n, announce, pieceLength, cashSize, threadNum, inputCreateName.value, "a.torrent", onPro).then((_) {
            inputLink.href = "dummy";
            inputLink.style.display = "block";
          });
        }
      });
    });
    inputLink.onClick.listen((_) {
      print("click");
      createFileModel.saveFile().then((_) {}).catchError((e) {
        dialog.show("failed save file");
      });
    });
  }
}
