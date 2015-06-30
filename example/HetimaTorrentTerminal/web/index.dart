library app;

import 'dart:html' as html;
import 'dart:async';
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';

import 'package:hetimatorrent/hetimatorrent.dart';
import 'terminal.dart';
import 'dialogtab.dart';

Tab tab = new Tab({"#m00_clone": "#con-clone"});
Dialog dialog = new Dialog();
Map<String, TorrentFile> managedTorrentFile = {};

html.InputElement fileInput = html.querySelector("#fileinput");
html.InputElement managedfile = html.querySelector("#managedfile");

// TrackerServer trackerServer = new TrackerServer(new HetiSocketBuilderChrome());
UpnpPortMapHelper portMapHelder = new UpnpPortMapHelper(new HetiSocketBuilderChrome(), "HetimaTorrentTracker");

//
//
html.SpanElement torrentHashSpan = html.querySelector("#torrent-hash");
html.SpanElement torrentRemoveBtn = html.querySelector("#torrent-remove-btn");

bool upnpIsUse = false;
String selectKey = null;

TorrentClient torrentClient = null;

void main() {
  print("hello world");
  
  tab.init();
  dialog.init();

  torrentRemoveBtn.onClick.listen((html.MouseEvent e) {
    if(selectKey != null) {
      tab.remove(selectKey);
      managedTorrentFile.remove(selectKey);
      print("##===> ${managedTorrentFile.length}");
      selectKey = null;
    }
  });

  fileInput.onChange.listen((html.Event e) {
    print("==");
    List<html.File> s = [];
    s.addAll(fileInput.files);
    while (s.length > 0) {
      html.File n = s.removeAt(0);
      print("#${n.name} ${e}");
      TorrentFile.createTorrentFileFromTorrentFile(new HetimaFileToBuilder(new HetimaDataBlob(n))).then((TorrentFile f) {
        return f.createInfoSha1().then((List<int> infoHash) {
          String key = PercentEncode.encode(infoHash);
          managedTorrentFile[key] = f;
          tab.add("${key}", "con-termi");
          return TorrentEngine.createTorrentEngine(new HetiSocketBuilderChrome(), f).then((TorrentEngine engine) {
            Terminal terminal = new Terminal(engine, '#command-input-line', '#command-output', '#command-cmdline');
            Terminal terminalReceive = new Terminal(engine,'#event-input-line', '#event-output', '#event-cmdline');
 
            terminal.addCommand(StartTorrentClientCommand.name, StartTorrentClientCommand.builder());
            terminal.addCommand(GetLocalIpCommand.name, GetLocalIpCommand.builder());
            terminal.addCommand(StartUpnpPortMapCommand.name, StartUpnpPortMapCommand.builder());
            terminal.addCommand(StopUpnpPortMapCommand.name, StopUpnpPortMapCommand.builder());
            terminal.addCommand(GetUpnpPortMapInfoCommand.name, GetUpnpPortMapInfoCommand.builder());
            terminal.addCommand(TrackerCommand.name, TrackerCommand.builder());
            terminal.addCommand(GetPeerInfoCommand.name, GetPeerInfoCommand.builder());
            terminal.addCommand(HandshakeCommand.name, HandshakeCommand.builder());
            terminal.addCommand(ConnectCommand.name, ConnectCommand.builder());
            engine.torrentClient.onReceiveEvent.listen((TorrentClientMessage info) {
              print("[receive message :  ${info.message.id}");
              terminalReceive.append("receive message : ${info.message.id}");
            });
          });
        });
      }).catchError((e) {
        dialog.show("failed parse torrent");
      });
    }
  });

  tab.onShow.listen((TabInfo info) {
    String t = info.cont;
    print("=t= ${t}");

      String key = info.key;
      if (managedTorrentFile.containsKey(key)) {
        torrentHashSpan.setInnerHtml("${info.key}");
        selectKey = key;
//        List<int> infoHash = PercentEncode.decode(info.key);
//        torrentNumOfPeerSpan.setInnerHtml("${trackerServer.numOfPeer(infoHash)}");
      }
  });

}

