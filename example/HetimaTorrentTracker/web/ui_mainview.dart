library app.mainview;

import 'dart:html' as html;
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'modeL_tracker.dart';

class MainItem {
  html.InputElement fileInput = html.querySelector("#fileinput");
  html.InputElement managedfile = html.querySelector("#managedfile");

  html.InputElement startServerBtn = html.querySelector("#startserver");
  html.InputElement stopServerBtn = html.querySelector("#stopserver");
  html.InputElement loadServerBtn = html.querySelector("#loaderserver");

  html.SpanElement outputLocalAddressSpn = html.querySelector("#localaddress");
  html.SpanElement outputLocalPortSpn = html.querySelector("#localport");
  html.SpanElement outputGlobalAddressSpn = html.querySelector("#globaladdress");
  html.SpanElement outputGlobalPortSpn = html.querySelector("#globalport");

  html.InputElement inputLocalAddress = html.querySelector("#input-localaddress");
  html.InputElement inputLocalPort = html.querySelector("#input-localport");
  html.InputElement inputGlobalPort = html.querySelector("#input-globalport");

  void init(TrackerModel model, Map<String, TorrentFile> managedTorrentFile, Tab tab, Dialog dialog) {
    fileInput.onChange.listen((html.Event e) {
      print("==");
      List<html.File> s = [];
      s.addAll(fileInput.files);
      while (s.length > 0) {
        html.File n = s.removeAt(0);
        print("#${n.name} ${e}");
        TorrentFile.createTorrentFileFromTorrentFile(new HetimaFileToBuilder(new HetimaDataBlob(n))).then((TorrentFile f) {
          return f.createInfoSha1().then((List<int> infoHash) {
            String key = PercentEncode.encode(infoHash);
            managedTorrentFile[key] = f;
            tab.add("${key}", "con-now");
            model.onAddInfoHashFromTracker(f);
          });
        }).catchError((e) {
          dialog.show("failed parse torrent");
        });
      }
    });

    startServerBtn.onClick.listen((html.MouseEvent e) {
      loadServerBtn.style.display = "block";
      stopServerBtn.style.display = "none";
      startServerBtn.style.display = "none";

      model.onStart(inputLocalAddress.value, int.parse(inputLocalPort.value), int.parse(inputGlobalPort.value)).then((List<String> v) {
        outputLocalPortSpn.innerHtml = v[1];
        outputLocalAddressSpn.innerHtml = v[0];
        stopServerBtn.style.display = "block";
        startServerBtn.style.display = "none";
        loadServerBtn.style.display = "none";
      }).catchError((e) {
        stopServerBtn.style.display = "none";
        startServerBtn.style.display = "block";
        loadServerBtn.style.display = "none";
      });
    });

    stopServerBtn.onClick.listen((html.MouseEvent e) {
      loadServerBtn.style.display = "block";
      stopServerBtn.style.display = "none";
      startServerBtn.style.display = "none";

      model.onStop().then((StopResult r) {
        startServerBtn.style.display = "block";
        stopServerBtn.style.display = "none";
        loadServerBtn.style.display = "none";
      }).catchError((e) {
        startServerBtn.style.display = "none";
        stopServerBtn.style.display = "block";
        loadServerBtn.style.display = "none";
      });
    });

    // Adds a click event for each radio button in the group with name "gender"
    html.querySelectorAll('[name="upnpon"]').forEach((html.InputElement radioButton) {
      radioButton.onClick.listen((html.MouseEvent e) {
        html.InputElement clicked = e.target;
        print("The user is ${clicked.value}");
        if (clicked.value == "Use") {
          model.upnpIsUse = true;
        } else {
          model.upnpIsUse = false;
        }
      });
    });

    model.portMapHelder.onUpdateGlobalIp.listen((String globalIP) {
      outputGlobalAddressSpn.setInnerHtml(globalIP);
    });

    model.portMapHelder.onUpdateGlobalPort.listen((String globalPort) {
      outputGlobalPortSpn.setInnerHtml(globalPort);
    });

    model.portMapHelder.startGetLocalIp().then((StartGetLocalIPResult result) {
      inputLocalAddress.value = result.localIP;
    });
  }
}

class CreateItem {
  html.InputElement inputFile = html.querySelector("#create-fileinput");
  html.InputElement inputAnnounce = html.querySelector("#create-announce");
  html.InputElement inputPieceLength = html.querySelector("#create-piece-length");
  html.AnchorElement inputLink = html.querySelector("#create-link");
  html.File _rawFile = null;
  Dialog dialog = null;

  init(TrackerModel model, Map<String, TorrentFile> managedTorrentFile, Tab tab, Dialog d) {
    dialog = d;
    inputFile.onChange.listen((html.Event e) {
      print("==");
      if (inputFile.files.length > 0) {
        html.File n = inputFile.files[0];
        TorrentFileCreator cre = new TorrentFileCreator();
        cre.announce = inputAnnounce.value;
        cre.piececLength = int.parse(inputPieceLength.value);
        return cre.createFromSingleFile(new HetimaDataBlob(n)).then((TorrentFileCreatorResult r) {
          List<int> buffer = Bencode.encode(r.torrentFile.mMetadata);
          HetimaDataFS fs = new HetimaDataFS("a.torrent");
          return fs.write(buffer, 0).then((WriteResult r) {
            return fs.getEntry().then((html.Entry e) {
              inputLink.href = e.toUrl();
              (e as html.FileEntry).file().then((html.File f) {
                _rawFile = f;
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
//
//
class HashItem {
  html.SpanElement torrentHashSpan = html.querySelector("#torrent-hash");
  html.SpanElement torrentRemoveBtn = html.querySelector("#torrent-remove-btn");
  html.SpanElement torrentNumOfPeerSpan = html.querySelector("#torrent-num-of-peer");

  init(TrackerModel model, Map<String, TorrentFile> managedTorrentFile, Tab tab) {
    torrentRemoveBtn.onClick.listen((html.MouseEvent e) {
      if (model.selectKey != null) {
        tab.remove(model.selectKey);
        managedTorrentFile.remove(model.selectKey);
        model.onRemoveInfoHashFromTracker(PercentEncode.decode(model.selectKey));
        model.selectKey = null;
      }
    });
  }
  void contain(TrackerModel model, Map<String, TorrentFile> managedTorrentFile, String key) {
    if (managedTorrentFile.containsKey(key)) {
      torrentHashSpan.setInnerHtml("${key}");
      model.selectKey = key;
      List<int> infoHash = PercentEncode.decode(key);
      torrentNumOfPeerSpan.setInnerHtml("${model.onGetNumOfPeer(infoHash)}");
    }
  }
}

//
//
//
void main() {
  Tab tab = new Tab({"#m00_clone": "#com-clone", "#m00_create": "#com-create"});
  Dialog dialog = new Dialog();

  Map<String, TorrentFile> managedTorrentFile = {};
  TrackerModel model = new TrackerModel();
  HashItem item = null;
  MainItem mainImte = null;
  CreateItem createImte = new CreateItem();
  print("hello world");
  tab.init();
  dialog.init();
  item = new HashItem();
  mainImte = new MainItem();
  item.init(model, managedTorrentFile, tab);
  mainImte.init(model, managedTorrentFile, tab, dialog);
  createImte.init(model, managedTorrentFile, tab, dialog);

  tab.onShow.listen((TabInfo info) {
    print("=t= ${info.cont}");
    item.contain(model, managedTorrentFile, info.key);
  });
}
