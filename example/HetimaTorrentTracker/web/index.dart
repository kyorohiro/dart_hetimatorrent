library app;

import 'dart:html' as html;
import 'dart:async';
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

Tab tab = new Tab();
Dialog dialog = new Dialog();
Map<String,TorrentFile> managedTorrentFile = {};

html.InputElement fileInput = html.querySelector("#fileinput");
html.InputElement managedfile = html.querySelector("#managedfile");

html.InputElement startServerBtn = html.querySelector("#startserver");
html.InputElement stopServerBtn = html.querySelector("#stopserver");



void main() {
  print("hello world");
  tab.init();
  dialog.init();

  fileInput.onChange.listen((html.Event e) {
    print("==");
    List<html.File> s = [];
    s.addAll(fileInput.files);
    while(s.length > 0) {
      html.File n = s.removeAt(0);
      print("#${n.name} ${e}");
      TorrentFile.createTorrentFileFromTorrentFile(new HetimaFileToBuilder(new HetimaDataBlob(n)))
      .then((TorrentFile f) {
        return f.createInfoSha1().then((List<int> v) {
          String key = PercentEncode.encode(v);
          managedTorrentFile[key] = f;
        });
      }).catchError((e){
        dialog.show("failed parse torrent");
      });
    }
  });

  startServerBtn.onClick.listen((html.MouseEvent e) {
    stopServerBtn.style.display = "block";
    startServerBtn.style.display = "none";
  });
  stopServerBtn.onClick.listen((html.MouseEvent e) {
    startServerBtn.style.display = "block";
    stopServerBtn.style.display = "none";    
  });
  tab.onShow.listen((String t) {
    print("=t= ${t}");
    if(0 == t.compareTo("#con-file")) {
      managedfile.nodes.clear();
      for(String key in managedTorrentFile.keys) {
        String id = key.replaceAll("%","");
        managedfile.nodes.add(new html.Element.html("""<div><button id="btn_${id}">X</button><span>${key}</span></div>"""));
        html.ButtonElement btn = html.querySelector("#btn_${id}");
        btn.onClick.listen((html.MouseEvent e) {
          managedfile.nodes.remove(btn.parent);
        });
      }
    }
  });

  print("=s=");
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
  Map<String, String> tabs = {
    "#m00_file": "#con-file", //"#editor-file",
    "#m01_now": "#con-now", //"#editor-now",
    "#m00_clone": "#com-clone"
  };

  html.Element current = null;

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
    for (String t in tabs.keys) {
      html.Element i = html.querySelector(t);
      i.onClick.listen((html.MouseEvent e) {
        selectTab(t);
      });
    }
  }

  void display(List<String> displayList) {
    for (String t in tabs.keys) {
      if (displayList.contains(t)) {
        html.querySelector(tabs[t]).style.display = "block";
      } else {
        html.querySelector(tabs[t]).style.display = "none";
      }
    }
  }

  StreamController<String> _controller = new StreamController<String>();
  Stream<String> get onShow => _controller.stream;
  void update(List<String> ids) {
    for (String id in ids) {
      if (tabs.containsKey(id)) {
        _controller.add(tabs[id]);
      }
    }
  }
}
