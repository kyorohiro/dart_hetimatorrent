library app.mainview;

import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'ui_hashitem.dart';
import 'ui_mainview.dart';
import 'model_client.dart';
import 'dart:async';
import 'dart:html';
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';

class AppModel {
    String selectKey = "";
    bool useDHT = false;
    bool useUpnp = false;
    Map<String, TorrentFile> managedTorrentFile = {};
    Map<String, ClientModel> seedModels = {};
    
    static AppModel instance = new AppModel();
    static getInstance() {
      return instance;
    }
}


//
//
//
void main() {
  Tab tab = new Tab({"#m00_clone": "#com-clone"});
  Dialog dialog = new Dialog();

  HashItem item = null;
  MainItem mainItem = null;
  print("hello world");
  tab.init();
  dialog.init();
  item = new HashItem();
  mainItem = new MainItem();
  item.init(tab, dialog);
  mainItem.init(tab, dialog, item);

  tab.onShow.listen((TabInfo info) {
    print("=t= ${info.cont}");
    item.contain(info.key, dialog);
  });
}

Future saveFile(File _rawFile) {
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
