library app.mainview;

import 'dart:html' as html;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'ui_dialog.dart';
import 'ui_hashitem.dart';
import 'model_main.dart';

class MainItem {
  // main view
  html.InputElement fileInput = html.querySelector("#fileinput");
  html.DivElement fileList = html.querySelector("#com-files");

  // setting 
  html.InputElement globalAddress = html.querySelector("#torrent-input-globaladdress");
  html.InputElement localAddress = html.querySelector("#torrent-input-localaddress");
  html.InputElement localport = html.querySelector("#torrent-input-localport");
  html.InputElement globalport = html.querySelector("#torrent-input-globalport");
  html.ButtonElement startServerBtn = html.querySelector("#torrent-startserver");
  html.ButtonElement stopServerBtn = html.querySelector("#torrent-stopserver");
  html.ObjectElement loadServerBtn = html.querySelector("#torrent-loaderserver");

  html.InputElement upnpUse = html.querySelector("#torrent-upnpon-use");
  html.InputElement upnpUnuse = html.querySelector("#torrent-upnpon-unuse");

  cre(HetimaData d, Map<String, TorrentFile> managedTorrentFile, Tab tab, Dialog dialog, [html.File b=null]) {
    TorrentFile.createFromTorrentFile(new HetimaFileToBuilder(d)).then((TorrentFile f) {
      return f.createInfoSha1().then((List<int> infoHash) {
        String key = PercentEncode.encode(infoHash);
        if(managedTorrentFile.containsKey(key)) {
          dialog.show("Failed to start : already start");
          fileInput.style.display = "block";
          return;
        }
        else if(f.announce.contains("https://") || f.announce.contains("udp://")) {
          dialog.show("Failed to start : not soupprt https and udp tracker. ${f.announce}");
          fileInput.style.display = "block";
          return;
        }
        else {
          managedTorrentFile[key] = f;
          tab.add("${key}", "con-now");
          fileInput.style.display = "block";
        }
      });
    }).catchError((e) {
      dialog.show("Failed to parse torrent");
      fileInput.style.display = "block";
    });
  }


  void init(Tab tab, Dialog dialog, HashItem hitem) {
    AppModel model = AppModel.getInstance();
    fileInput.onChange.listen((html.Event e) {
      print("==");
      if (fileInput.files != null && fileInput.files.length > 0) {
        fileInput.style.display = "none";

        html.File n = fileInput.files[0];
 
        if (n.size == 0) {
          dialog.show("Failed: file size zero");
          fileInput.style.display = "block";
          return;
        } else {
          cre(new HetimaDataBlob(n), model.managedTorrentFile,  tab, dialog);
        }
      }
    });
    
    HetimaDataFS.getFiles().then((List<String> files) {
     for(String f in files) {
       print("ifile : ${f}");
       if(!f.endsWith(".cont")) {
         continue;
       }
       String key = f.replaceAll(".cont", "");
       fileList.children.clear();
       html.DivElement c = new html.Element.html("<div id=\"${key}\"></div>");
       html.InputElement startButton = new html.Element.html("<input type=\"button\" value=\"Start\">");
       html.InputElement removeButton = new html.Element.html("<input type=\"button\" value=\"X\">");
       c.children.add(startButton);
       c.children.add(removeButton);
       c.children.add(new html.Element.html("<span>${key}</span>"));
       c.children.add(new html.Element.html("<br>"));
       fileList.children.add(c);
       removeButton.onClick.listen((_){
         if(model.managedTorrentFile.containsKey(key)) {
           dialog.show("Failed to remove : you must to close tab");
           return;
         }
           
         HetimaDataFS.removeFile("${key}.cont").catchError((e){;});
         HetimaDataFS.removeFile("${key}.torrent").catchError((e){;});
         HetimaDataFS.removeFile("${key}.bitfield").catchError((e){;});

         fileList.children.remove(c);
       });
       startButton.onClick.listen((_){
         cre(new HetimaDataFS("${key}.torrent",persistent:false), model.managedTorrentFile,  tab, dialog);
       });
     }
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

    html.querySelectorAll('[name="torrent-dhton"]').forEach((html.InputElement radioButton) {
      radioButton.onClick.listen((html.MouseEvent e) {
        html.InputElement clicked = e.target;
        print("The user is ${clicked.value}");
        if (clicked.value == "Use") {
          model.useDHT = true;
        } else {
          model.useDHT = false;
        }
      });
    });
  }
}
