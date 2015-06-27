library app.mainview;

import 'dart:html' as html;
import 'dart:async';
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
//import 'ui_dialog.dart';
//import 'modeL_tracker.dart';

class TrackerModel {
  bool upnpIsUse = false;
  String selectKey = null;

///
  TrackerServer trackerServer = new TrackerServer(new HetiSocketBuilderChrome());
  UpnpPortMapHelper portMapHelder = new UpnpPortMapHelper(new HetiSocketBuilderChrome(), "HetimaTorrentTracker");

  void onRemoveInfoHashFromTracker(List<int> removeHash) {
    trackerServer.removeInfoHash(PercentEncode.decode(selectKey));
  }

  void onAddInfoHashFromTracker(TorrentFile f) {
    trackerServer.addInfoHash(f);
  }

  Future onStop() {
    // clear
    trackerServer.trackerAnnounceAddressForTorrentFile = "";

    portMapHelder.getPortMapInfo(portMapHelder.appid).then((GetPortMapInfoResult r) {
      if (r.infos.length > 0 && r.infos[0].externalPort.length != 0) {
        int port = int.parse(r.infos[0].externalPort);
        portMapHelder.deleteAllPortMap([port]);
      }
    }).catchError((e) {
      ;
    });

    return trackerServer.stop();
  }

  Future onStart(String localIP, int localPort, int globalPort) {
    trackerServer.address = localIP;
    trackerServer.port = localPort;
    return trackerServer.start().then((StartResult r) {
      if (upnpIsUse == true) {
        portMapHelder.basePort = globalPort;
        portMapHelder.numOfRetry = 0;
        portMapHelder.localAddress = localIP;
        portMapHelder.localPort = localPort;

        portMapHelder.startGetExternalIp().then((_) {}).catchError((e) {}).whenComplete(() {
          portMapHelder.startPortMap().then((_) {
            trackerServer.trackerAnnounceAddressForTorrentFile = "http://${portMapHelder.externalIp}:${portMapHelder.externalPort}/announce";
          }).catchError((e) {
            print("error ${e}");
          });
        });
      }
      return [trackerServer.address, "${trackerServer.port}"];
    });
  }

  int onGetNumOfPeer(List<int> infoHash) {
    return trackerServer.numOfPeer(infoHash);
  }
}

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
            concurrency: (threadNum>1), threadNum:threadNum,cache: (cashSize>0), cacheSize: cashSize, cacheNum: 3, progress:onPro).then((TorrentFileCreatorResult r) {
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

class Dialog {
  html.Element dialog = html.querySelector('#dialog');
  html.ButtonElement dialogBtn = html.querySelector('#dialog-btn');
  html.ButtonElement dialogMessage = html.querySelector('#dialog-message');

  Dialog() {
    init();
  }

  void init() {
    dialogBtn.onClick.listen((html.MouseEvent e) {
      dialog.style.display = "none";
    });
  }

  void show(String message) {
    dialog.style.left = "${html.window.innerWidth/2-100}px";
    dialog.style.top = "${html.window.innerHeight/2-100}px";
    dialog.style.position = "absolute";
    dialog.style.display = "block";
    dialog.style.width = "200px";
    dialog.style.zIndex = "50";
    dialogMessage.value = message;
  }
}

class Tab {
  html.InputElement tabContainer = html.querySelector("#tabcont");
  Map<String, String> tabs = {
    
  };

  html.Element current = null;

  int v = 100;
  Map<String, String> keyManager = {};
  
  Tab(Map<String,String> v) {
    tabs.addAll(v);
  }
  void add(String key, String cont) {
    keyManager[key] = "#d00_${v++}";
    tabs[keyManager[key]] = "#${cont}";
    html.Element e = new html.Element.html("""<li id="${(keyManager[key]).substring(1)}">${key.substring(0,4)}</li>""");
    tabContainer.append(e);
    updateTab();
  }

  void remove(String key) {
    tabs.remove(keyManager[key]);
    html.Element t = html.querySelector(keyManager[key]);
    if (t != null) {
      tabContainer.nodes.remove(t);
    }
    updateTab();
  }

  void selectTab(String id) {
    html.Element i = html.querySelector(id);
    print("##click ${i}");

    display([id]);
    i.classes.add("selected");
    if (current != null && current != i) {
      current.classes.remove("selected");
    }
    current = i;

    update([id]);
  }

  void init() {
    updateTab();
  }

  void updateTab() {
    for (String t in tabs.keys) {
      html.Element i = html.querySelector(t);
      i.onClick.listen((html.MouseEvent e) {
        selectTab(t);
      });
    }
  }

  void display(List<String> displayList) {
    List<html.Element> blockList = [];
    for (String t in tabs.keys) {
      if (displayList.contains(t)) {
        html.Element tt = html.querySelector(tabs[t]);
        if (tt != null) {
          blockList.add(tt);
        }
      } else {
        html.Element tt = html.querySelector(tabs[t]);
        if (tt != null) {
          tt.style.display = "none";
        }
      }
    }
    for(html.Element tt in blockList) {
      tt.style.display = "block";
    }
  }

  StreamController<TabInfo> _controller = new StreamController<TabInfo>();
  Stream<TabInfo> get onShow => _controller.stream;
  void update(List<String> ids) {
    for (String id in ids) {
      if (tabs.containsKey(id)) {
        TabInfo ret = new TabInfo()
                  ..cont = tabs[id]
                  ..key = id;
        if(keyManager.containsValue(id)){
          for(String key in keyManager.keys) {
            if(keyManager[key] == id) {
              ret.key = key;
              break;
            }
          }
        }
        _controller.add(ret);
      }
    }
  }
}

class TabInfo {
  String key;
  String cont;
}
