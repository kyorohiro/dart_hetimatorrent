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

  
 // html.InputElement managedfile = html.querySelector("#managedfile");

  // setting view
  html.InputElement inputLocalAddress = html.querySelector("#input-localaddress");
  html.InputElement inputLocalPort = html.querySelector("#input-localport");
  html.InputElement inputGlobalPort = html.querySelector("#input-globalport");

  void init(AppModel model, Map<String, TorrentFile> managedTorrentFile, Tab tab, Dialog dialog, HashItem hitem) {
    fileInput.onChange.listen((html.Event e) {
      print("==");
      if (fileInput.files != null && fileInput.files.length > 0) {
        fileInput.style.display = "none";

        html.File n = fileInput.files[0];
        cre(HetimaData d,[html.File b=null]) {
          TorrentFile.createTorrentFileFromTorrentFile(new HetimaFileToBuilder(d)).then((TorrentFile f) {
            return f.createInfoSha1().then((List<int> infoHash) {
              String key = PercentEncode.encode(infoHash);
              managedTorrentFile[key] = f;
              tab.add("${key}", "con-now");
              fileInput.style.display = "block";
            });
          }).catchError((e) {
            dialog.show("Failed to parse torrent");

            fileInput.style.display = "block";
          });
        }
 
        if (n.size == 0) {
          dialog.show("Failed: file size zero");
          fileInput.style.display = "block";
          return;
        } else {
          cre(new HetimaDataBlob(n));
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
         HetimaDataFS.removeFile("${key}.cont").catchError((e){;});
         HetimaDataFS.removeFile("${key}.torrent").catchError((e){;});
         fileList.children.remove(c);
       });
     }
    });
  }
}
