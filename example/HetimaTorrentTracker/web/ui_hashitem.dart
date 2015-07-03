library app.mainview.hashitem;

import 'dart:html' as html;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'model_tracker.dart';

//
//
class HashItem {
  html.SpanElement torrentHashSpan = html.querySelector("#torrent-hash");
  html.SpanElement torrentRemoveBtn = html.querySelector("#torrent-remove-btn");
  html.SpanElement torrentNumOfPeerSpan = html.querySelector("#torrent-num-of-peer");
// "torrent-upnpon"
  
  html.InputElement seedFile = html.querySelector("#torrent-seedfile");
  html.InputElement localAddress = html.querySelector("#torrent-input-localaddress");
  html.InputElement localport = html.querySelector("#torrent-input-localport");
  html.InputElement globalport = html.querySelector("#torrent-input-globalport");
  html.ButtonElement startServerBtn = html.querySelector("#torrent-startserver");
  html.ButtonElement stopServerBtn = html.querySelector("#torrent-stopserver");
  html.ObjectElement loadServerBtn = html.querySelector("#torrent-loaderserver");
     
     
  init(TrackerModel model, Map<String, TorrentFile> managedTorrentFile, Tab tab) {
    torrentRemoveBtn.onClick.listen((html.MouseEvent e) {
      if (model.selectKey != null) {
        tab.remove(model.selectKey);
        managedTorrentFile.remove(model.selectKey);
        model.removeInfoHashFromTracker(PercentEncode.decode(model.selectKey));
        model.selectKey = null;
      }
    });
    
    seedFile.onChange.listen((html.Event e) {
      print("==");
      if(seedFile.files.length <= 0) {
        return;
      }
      localAddress.style.display = "block";
      localport.style.display  = "block";
      globalport.style.display  = "block";
      startServerBtn.style.display  = "block";
      stopServerBtn.style.display  = "none";
      loadServerBtn.style.display  = "none";
    });
    
    startServerBtn.onClick.listen((html.MouseEvent e) {
      loadServerBtn.style.display = "block";
      stopServerBtn.style.display = "none";
      startServerBtn.style.display = "none";

      model.startTracker(localAddress.value, int.parse(localport.value), int.parse(globalport.value)).then((List<String> v) {
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

      model.stopTracker().then((StopResult r) {
        startServerBtn.style.display = "block";
        stopServerBtn.style.display = "none";
        loadServerBtn.style.display = "none";
      }).catchError((e) {
        startServerBtn.style.display = "none";
        stopServerBtn.style.display = "block";
        loadServerBtn.style.display = "none";
      });
    });
  }

  void contain(TrackerModel model, Map<String, TorrentFile> managedTorrentFile, String key) {
    if (managedTorrentFile.containsKey(key)) {
      torrentHashSpan.setInnerHtml("${key}");
      model.selectKey = key;
      List<int> infoHash = PercentEncode.decode(key);
      torrentNumOfPeerSpan.setInnerHtml("${model.getNumOfPeer(infoHash)}");
    }
  }
}
