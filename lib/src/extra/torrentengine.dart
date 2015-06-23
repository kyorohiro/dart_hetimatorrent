library hetimatorrent.extra.torrentengine;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

abstract class TorrentEngineCommand {
  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null});
  static String get help => "";
}

class TorrentEngineCommandBuilder {
  Function builder = null; //TorrentEngineCommand builder(List<String> list);
  String help = "";
  TorrentEngineCommandBuilder(Function builder, String help) {
    this.builder = builder;
    this.help = help;
  }
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
  TorrentClient get torrentClient => _torrentClient;
  TrackerClient get trackerClient =>_trackerClient;
  UpnpPortMapHelper get upnpPortMapClient => _upnpPortMapClient;

  TorrentEngine._empty() {
    ;
  }

  static Future<TorrentEngine> createTorrentEngine(HetiSocketBuilder builder, TorrentFile torrentfile, {appid: "hetima_torrent_engine"}) {
    return new Future(() {
      TorrentEngine engine = new TorrentEngine._empty();
      return TrackerClient.createTrackerClient(builder, torrentfile).then((TrackerClient trackerClient) {
        engine._builder = builder;
        engine._trackerClient = trackerClient;
        engine._torrentClient = new TorrentClient(builder, trackerClient.infoHash, trackerClient.peerId);
        engine._upnpPortMapClient = new UpnpPortMapHelper(builder, appid);
        return engine;
      });
    });
  }

}
