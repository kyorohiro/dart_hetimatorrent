library app.mainview.hashitem;

import 'dart:html' as html;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'model_tracker.dart';
import 'model_seeder.dart';


//
//
class HashItem {
  html.SpanElement torrentHashSpan = html.querySelector("#torrent-hash");
  html.SpanElement torrentRemoveBtn = html.querySelector("#torrent-remove-btn");
  html.SpanElement torrentNumOfPeerSpan = html.querySelector("#torrent-num-of-peer");
// "torrent-upnpon"
  
  html.InputElement seedFile = html.querySelector("#torrent-seedfile");
  
  html.InputElement globalAddress = html.querySelector("#torrent-input-globaladdress");
  html.InputElement localAddress = html.querySelector("#torrent-input-localaddress");
  html.InputElement localport = html.querySelector("#torrent-input-localport");
  html.InputElement globalport = html.querySelector("#torrent-input-globalport");
  html.ButtonElement startServerBtn = html.querySelector("#torrent-startserver");
  html.ButtonElement stopServerBtn = html.querySelector("#torrent-stopserver");
  html.ObjectElement loadServerBtn = html.querySelector("#torrent-loaderserver");

  html.File seedRawFile = null;
  init(TrackerModel trackerModel, Map<String, TorrentFile> managedTorrentFile, Tab tab) {
    SeederModel model = new SeederModel();

    torrentRemoveBtn.onClick.listen((html.MouseEvent e) {
      if (trackerModel.selectKey != null) {
        tab.remove(trackerModel.selectKey);
        managedTorrentFile.remove(trackerModel.selectKey);
        trackerModel.removeInfoHashFromTracker(PercentEncode.decode(trackerModel.selectKey));
        trackerModel.selectKey = null;
      }
    });
    
    seedFile.onChange.listen((html.Event e) {
      print("==");
      if(seedFile.files.length <= 0) {
        return;
      }
      seedRawFile = seedFile.files[0];
      localAddress.style.display = "block";
      localport.style.display  = "block";
      globalAddress.style.display = "block";
      globalport.style.display  = "block";
      startServerBtn.style.display  = "block";
      stopServerBtn.style.display  = "none";
      loadServerBtn.style.display  = "none";
    });
    
    startServerBtn.onClick.listen((html.MouseEvent e) {
      loadServerBtn.style.display = "block";
      stopServerBtn.style.display = "none";
      startServerBtn.style.display = "none";
      TorrentFile torrentFile = managedTorrentFile[trackerModel.selectKey];
      model.globalPort = int.parse(globalport.value);
      model.localPort = int.parse(localport.value);
      model.localIp = localAddress.value;
      model.globalIp = globalAddress.value;
      model.startEngine(torrentFile, new HetimaDataBlob(seedFile), true).then((SeederModelStartResult ret) {
        localAddress.value = ret.localIp;
        localport.value = "${ret.localPort}";
        globalport.value = "${ret.globalPort}";
        globalAddress.value = "${ret.globalIp}";
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

      model.stopEngine().then((StopResult r) {
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
    html.querySelectorAll('[name="torrent-upnpon"]').forEach((html.InputElement radioButton) {
      radioButton.onClick.listen((html.MouseEvent e) {
        html.InputElement clicked = e.target;
        print("The user is ${clicked.value}");
        if (clicked.value == "Use") {
          model.useUpnp = true;
        } else {
          model.useUpnp = false;
        }
      });
    });
    
    html.querySelectorAll('[name="torrent-upnpon"]').forEach((html.InputElement radioButton) {
      radioButton.onClick.listen((html.MouseEvent e) {
        html.InputElement clicked = e.target;
        print("The user is ${clicked.value}");
        if (clicked.value == "Use") {
          model.useUpnp = true;
        } else {
          model.useUpnp  = false;
        }
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
