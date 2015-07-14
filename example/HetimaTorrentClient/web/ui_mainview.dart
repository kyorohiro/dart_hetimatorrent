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
  html.InputElement fileInput = html.querySelector("#fileinput");
  html.InputElement managedfile = html.querySelector("#managedfile");

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
      print("==== ${f} ====");
    }
  });
  }
}
