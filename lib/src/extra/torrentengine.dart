library hetimatorrent.extra.torrentengine;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import 'torrentengineai.dart';

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
  TrackerClient get trackerClient => _trackerClient;
  UpnpPortMapHelper get upnpPortMapClient => _upnpPortMapClient;

  TorrentEngineAI ai = null;
  
  int get localPort => _torrentClient.localPort;
  String get localIp => _torrentClient.localAddress;
  int get globalPort => _torrentClient.globalPort;

  TorrentEngine._empty() {
    ;
  }

  static Future<TorrentEngine> createTorrentEngine(HetiSocketBuilder builder, TorrentFile torrentfile, HetimaData cash, 
      {appid: "hetima_torrent_engine",
      haveAllData: false, 
      String localAddress: "0.0.0.0",
      int localPort: 18085,int globalPort: 18085,
      int retryNum:10, bool useUpnp:false}) {
    return new Future(() {
      TorrentEngine engine = new TorrentEngine._empty();
      return TrackerClient.createTrackerClient(builder, torrentfile).then((TrackerClient trackerClient) {
        engine._builder = builder;
        engine._trackerClient = trackerClient;
        engine._torrentClient = new TorrentClient(builder, trackerClient.peerId, trackerClient.infoHash, torrentfile.info.pieces, torrentfile.info.piece_length, torrentfile.info.files.dataSize, cash,
            ai: engine.ai, haveAllData: haveAllData);
        engine._upnpPortMapClient = new UpnpPortMapHelper(builder, appid);
        engine.ai = new TorrentEngineAI(engine._torrentClient, engine._trackerClient, engine._upnpPortMapClient);
        engine.ai.baseLocalAddress = localAddress;
        engine.ai.baseLocalPort = localPort;
        engine.ai.baseGlobalPort = globalPort;
        engine.ai.baseNumOfRetry = retryNum;
        engine.ai.usePortMap = useUpnp;
        return engine;
      });
    });
  }

  Future go({usePortMap: false}) {
    ai.usePortMap = usePortMap;
    return ai.go();
  }

  Future stop() {
    return ai.stop();
  }
}
