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
  HetiSocketBuilder _builder = null;

  HetiSocketBuilder get socketBuilder => _builder;

  TorrentEngine._empty() {
    ;
  }

  static Future<TorrentEngine> createTorrentEngine(HetiSocketBuilder builder, TorrentFile torrentfile,{appid:"hetima_torrent_engine"}) {
    return new Future(() {
      TorrentEngine engine = new TorrentEngine._empty();
      return TrackerClient.createTrackerClient(builder, torrentfile).then((TrackerClient trackerClient) {
        engine._trackerClient = trackerClient;
        engine._torrentClient = new TorrentClient(builder);
        engine._builder = builder;
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

  StartTorrentClientCommand(String localIp, int localPort) {
    this.localIp = localIp;
    this.localPort = localPort;
  }

  static TorrentEngineCommand builder(List<String> list) {
    return new StartTorrentClientCommand(list[0], int.parse(list[1]));
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

  static TorrentEngineCommand builder(List<String> list) {
    return new UpnpPortMapCommand(list[0], int.parse(list[1]), int.parse(list[2]));
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

class GetLocalIpCommand extends TorrentEngineCommand {
  GetLocalIpCommand() {
  }

  static TorrentEngineCommand builder(List<String> list) {
    return new GetLocalIpCommand();
  }

  Future<CommandResult> execute(TorrentEngine engine,{List<String> args:null}) {
    return new Future((){
      return engine.socketBuilder.getNetworkInterfaces().then((List<HetiNetworkInterface> l) {
        StringBuffer buffer = new StringBuffer();
        for(HetiNetworkInterface i in l) {
          buffer.writeln("address:${i.address}, name:${i.name}");
        }
        return new CommandResult(buffer.toString());
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
