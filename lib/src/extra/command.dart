library hetimatorrent.extra.command;

import 'dart:html' as html;
import 'dart:async';
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

abstract class TorrentEngineCommand {
  Future<CommandResult> execute(TorrentEngine engine,{List<String> args:null});
}

class CommandResult {
  String message = "";
  CommandResult(String message) {
    this.message = message;
  }
}

class TorrentEngine {
  TorrentClient _torrentClient = null;
  TrackerClient _trackerClient = null;
  UpnpPortMapHelper _upnpPortMapClient = null;

  TorrentEngine._empty() {
    ;
  }

  static Future<TrackerClient> createTorrentEngine(HetiSocketBuilder builder, TorrentFile torrentfile,{appid:"hetima_torrent_engine"}) {
    return new Future(() {
      TorrentEngine engine = new TorrentEngine._empty();
      return TrackerClient.createTrackerClient(builder, torrentfile).then((TrackerClient trackerClient) {
        engine._trackerClient = trackerClient;
        engine._torrentClient = new TorrentClient(builder);
        new UpnpPortMapHelper(builder, appid);
        return engine;
      });
    });
  }

  TrackerClient get trackerClient => this._trackerClient;
}


class StartTorrentClientCommand extends TorrentEngineCommand {
  String localIp = "";
  int localPort = 0;
  StartTorrentClient(String localIp, int localPort) {
    this.localIp = localIp;
    this.localPort = localPort;
  }

  Future<CommandResult> execute(TorrentEngine engine,{List<String> args:null}) {
    return new Future((){
      engine._torrentClient.localAddress = localIp;
      engine._torrentClient.port = localPort;
      return engine._torrentClient.start().then((_) {
        return new CommandResult("started ${engine._torrentClient.localAddress} ${engine._torrentClient.port}");
      });
    });
  }
}

class UpnpPortMapCommand extends TorrentEngineCommand {
  String localIp = "";
  int localPort = 0;
  int globalPort = 0;

  UpnpPortMapCommand(String localIp, int localPort, int globalPort) {
    this.localIp = localIp;
    this.localPort = localPort;
    this.globalPort = globalPort;
  }

  Future<CommandResult> execute(TorrentEngine engine,{List<String> args:null}) {
    return new Future((){
      engine._upnpPortMapClient.localAddress = localIp;
      engine._upnpPortMapClient.basePort = globalPort;
      engine._upnpPortMapClient.localPort = localPort;
      engine._upnpPortMapClient.numOfRetry = 0;
      return engine._upnpPortMapClient.startPortMap().then((StartPortMapResult result) {
        return new CommandResult("portmapped ${result.hashCode}");
      });
    });
  }
}

class TrackerCommand extends TorrentEngineCommand  {
  Future<CommandResult> execute(TorrentEngine engine,{List<String> args:null}) {
    Completer<CommandResult> comp = new Completer();
    engine.trackerClient.request().then((TrackerRequestResult result) {
      print("");
    });

    return comp.future;
  }
}
