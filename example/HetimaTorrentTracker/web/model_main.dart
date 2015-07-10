library app.mainview;

import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'model_tracker.dart';
import 'ui_hashitem.dart';
import 'ui_mainview.dart';


//
//
//
void main() {
  Tab tab = new Tab({"#m00_clone": "#com-clone"});
  Dialog dialog = new Dialog();

  Map<String, TorrentFile> managedTorrentFile = {};
  TrackerModel model = new TrackerModel();
  HashItem item = null;
  MainItem mainImte = null;
  print("hello world");
  tab.init();
  dialog.init();
  item = new HashItem();
  mainImte = new MainItem();
  item.init(model, managedTorrentFile, tab, dialog);
  mainImte.init(model, managedTorrentFile, tab, dialog);

  tab.onShow.listen((TabInfo info) {
    print("=t= ${info.cont}");
    item.contain(model, managedTorrentFile, info.key);
  });
}


