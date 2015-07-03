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
  html.ButtonElement startServer = html.querySelector("#torrent-startserver");
  html.ButtonElement stopServer = html.querySelector("#torrent-stopserver");
  html.ObjectElement loadServer = html.querySelector("#torrent-loaderserver");
     
     
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
      startServer.style.display  = "block";
      stopServer.style.display  = "none";
      loadServer.style.display  = "none";
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
