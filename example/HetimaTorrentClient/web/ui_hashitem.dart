library app.mainview.hashitem;

import 'dart:html' as html;
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimafile/hetimafile_cl.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'model_client.dart';
import 'model_main.dart';
import 'package:chrome/chrome_app.dart' as chrome;

//
//
class HashItem {
  html.SpanElement torrentHashSpan = html.querySelector("#torrent-hash");
  html.SpanElement torrentRemoveBtn = html.querySelector("#torrent-remove-btn");

  html.ButtonElement startServerBtn = html.querySelector("#torrent-startserver");
  html.ButtonElement stopServerBtn = html.querySelector("#torrent-stopserver");
  html.ObjectElement loadServerBtn = html.querySelector("#torrent-loaderserver");

  html.SpanElement torrentProgressSpan = html.querySelector("#torrent-progress");
//
//  html.AnchorElement torrentOutput = html.querySelector("#torrent-output");
//
  html.DivElement torrentOutputs = html.querySelector("#torrent-outputs");
  html.DivElement torrentOutputsLoading = html.querySelector("#torrent-outputs-loading");
  html.DivElement torrentOutputFailreReason = html.querySelector("#torrent-tracker-failurereason");

  Map<String, int> seedState = {};

//  html.File seedRawFile = null;
  onProgress(int x, int a, TorrentEngineProgress info) {
    torrentProgressSpan.setInnerHtml("${x}/${a} : ${100*x~/a}");
    if (info != null) {
      if (info.trackerIsOk == true) {
        torrentOutputFailreReason.style.color = "#0000FF";
        torrentOutputFailreReason.setInnerHtml("Tracker status is good");
      } else {
        torrentOutputFailreReason.style.color = "#FF0000";
        torrentOutputFailreReason.setInnerHtml("Tracker status is worng : ${info.trackerFailureReason}");
      }
    }
  }
  init(Tab tab, Dialog dialog) {
    AppModel appModel = AppModel.getInstance();
    void stop() {
      String key = appModel.selectKey;
      loadServerBtn.style.display = "block";
      stopServerBtn.style.display = "none";
      startServerBtn.style.display = "none";
      seedState[key] = 3; //loading
      appModel.seedModels[key].stopEngine().then((StopResult r) {
        seedState[key] = 1; //start
        startServerBtn.style.display = "block";
        stopServerBtn.style.display = "none";
        loadServerBtn.style.display = "none";
      }).catchError((e) {
        seedState[key] = 2; //stop
        startServerBtn.style.display = "none";
        stopServerBtn.style.display = "block";
        loadServerBtn.style.display = "none";
        dialog.show("Failed to stop torrent");
      }).whenComplete(() {
        AppModel.getInstance().get().then((TorrentEngine e) {
          AppModel mo = AppModel.getInstance();
          if (e.numOfTorrent > 0) {
            mo.mainItem.setStartState(true);
          } else {
            mo.mainItem.setStartState(false);
          }
        });
      });
    }

    void start() {
      String key = appModel.selectKey;
      loadServerBtn.style.display = "block";
      stopServerBtn.style.display = "none";
      startServerBtn.style.display = "none";
      seedState[key] = 3; //loading
      TorrentFile torrentFile = appModel.managedTorrentFile[appModel.selectKey];
      AppModel mo = AppModel.getInstance();
      mo.mainItem.setStartState(true);
      appModel.seedModels[key].startEngine(torrentFile, onProgress).then((SeederModelStartResult ret) {
        seedState[key] = 2; //stop
        stopServerBtn.style.display = "block";
        startServerBtn.style.display = "none";
        loadServerBtn.style.display = "none";
      }).catchError((e) {
        seedState[key] = 1; //start
        stopServerBtn.style.display = "none";
        startServerBtn.style.display = "block";
        loadServerBtn.style.display = "none";
        dialog.show("Failed to start torrent");

        if (e.numOfTorrent() > 0) {
          mo.mainItem.setStartState(true);
        } else {
          mo.mainItem.setStartState(false);
        }
      });
    }
    torrentRemoveBtn.onClick.listen((html.MouseEvent e) {
      if (appModel.selectKey != null) {
        stop();
        tab.remove(appModel.selectKey);
        appModel.managedTorrentFile.remove(appModel.selectKey);
        appModel.selectKey = null;
      }
    });

    startServerBtn.onClick.listen((html.MouseEvent e) {
      start();
    });

    stopServerBtn.onClick.listen((html.MouseEvent e) {
      stop();
    });
  }

  void contain(String key, Dialog dialog) {
    AppModel model = AppModel.getInstance();
    if (model.managedTorrentFile.containsKey(key)) {
      if (false == model.seedModels.containsKey(key)) {
        model.seedModels[key] = new ClientModel(key, model.managedTorrentFile[key]);
      }

      torrentHashSpan.setInnerHtml("${key}");
      model.selectKey = key;

      if (seedState.containsKey(key) == false || seedState[key] == 1) {
        //start
        startServerBtn.style.display = "block";
        stopServerBtn.style.display = "none";
        loadServerBtn.style.display = "none";
      } else if (seedState[key] == 2) {
        //stop
        startServerBtn.style.display = "none";
        stopServerBtn.style.display = "block";
        loadServerBtn.style.display = "none";
      } else if (seedState[key] == 3) {
        //loading
        startServerBtn.style.display = "none";
        stopServerBtn.style.display = "none";
        loadServerBtn.style.display = "block";
      }

      //
      //
      torrentOutputs.children.clear();
      TorrentFile torrentFile = model.managedTorrentFile[key];
      for (TorrentFileFile file in torrentFile.info.files.files) {
        html.AnchorElement elm = new html.Element.html("<a href=\"dummy\">${file.pathAsString} :${file.fileSize}byte</a>");
        torrentOutputs.children.add(elm);

        TorrentFileFile f = file;
        elm.onClick.listen((_) {
          print("click");
          String key = model.selectKey;
          torrentOutputs.style.display = "none";
          torrentOutputsLoading.style.display = "block";
          saveFile(model.seedModels[key].seedfile, f.index, f.index + f.fileSize, f.path.last).then((e) {
            torrentOutputs.style.display = "block";
            torrentOutputsLoading.style.display = "none";
          }).catchError((e) {
            torrentOutputs.style.display = "block";
            torrentOutputsLoading.style.display = "none";
          });
        });
      }

      model.seedModels[key].getCurrentProgress().then((int progress) {
        int a = torrentFile.info.files.dataSize;
        int x = progress;
        onProgress(x, a, null);
      }).catchError((e) {
        dialog.show("Failed to load torrent file . please restart app");
      });
    }
  }

  Future saveFile(HetimaData copyFrom, [int begin = 0, int end = null, String name = "rawdata"]) async {
    chrome.ChooseEntryResult chooseEntryResult = await chrome.fileSystem.chooseEntry(new chrome.ChooseEntryOptions(type: chrome.ChooseEntryType.SAVE_FILE, suggestedName: name));
    chrome.ChromeFileEntry copyTo = await chrome.fileSystem.getWritableEntry(chooseEntryResult.entry);
    ///
    int length = await copyFrom.getLength();
    print("###[ A1 ]#length = ${length} ${end}");
    //
    if (end == null) {
      end = length;
    }
    num d = 32 * 1024 * 1024;
    num b = begin;
    if(d>(end-begin)) {
      d = end-begin;
    }
    num e = b + d;
    int retry = 0;
    DomJSHetiFile hetiCopyTo = new DomJSHetiFile.create(copyTo.jsProxy);
    HetimaData data = await hetiCopyTo.getHetimaFile();
    while (true) {
      print("###[ A2 ]#${b} ${e} ${e-b}");
      ReadResult readResult = await copyFrom.read(b, e - b);
      print("${b} ${e} ${readResult.buffer.length} ## ${b-begin}");
      try {
        await data.write(readResult.buffer, b - begin);
        retry = 0;
        b = e;
        e = b + d;
        if (e > end) {
          e = end;
        }
        if (b < end) {
          // loop
        } else {
          break;
        }
      } catch (e) {
        if (retry >= 5) {
          throw e;
        }
        await new Future.delayed(new Duration(seconds: 1));
        retry++;
      }
    }
    await hetiCopyTo.truncate(end-begin);
  }
}
