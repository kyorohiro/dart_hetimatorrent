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
import 'package:hetimanet/hetimanet_chrome.dart';

class AppModel {

  //
  //
  String selectKey = "";
  bool useDHT = false;
  bool useUpnp = false;
  Map<String, TorrentFile> managedTorrentFile = {};
  Map<String, ClientModel> seedModels = {};
  //
  //
  String globalIp = "0.0.0.0";
  String localIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;

  static AppModel instance = new AppModel();
  static AppModel getInstance() {
    return instance;
  }

  TorrentEngine _engine = null;

  Future<TorrentEngine> get() {
    return new Future(() {
      if (_engine == null) {
        _engine = new TorrentEngine(new HetiSocketBuilderChrome(),
            globalPort: globalPort, localPort: localPort, localIp: localIp, globalIp: globalIp, useUpnp: useUpnp, useDht: useDHT, appid: "hetimatorrentclient");
      }
      return _engine;
    });
  }

  Future<TorrentEngine> start() {
    return get().then((TorrentEngine _engine) {

      if (false == _engine.isStart) {
        return _engine.start().then((_) {
          _engine.addBootNode(mainItem.getBootIp(), mainItem.getBootPort());
          return _engine;
        });
      } else {
        return _engine;
      }
    });
  }

  Future stop() {
    return new Future(() {
      if (_engine != null && _engine.isStart == true) {
        _engine.stop();
      }
    });
  }
  
  //
  //
  HashItem hashItem = null;
  MainItem mainItem = null;
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
  AppModel.getInstance().hashItem = item = new HashItem();
  AppModel.getInstance().mainItem = mainItem = new MainItem();
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
