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
  TorrentClientManager _torrentClientManager = null;
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
  String get globalIp => _torrentClient.globalIp;

//  TorrentEngineDHTMane _dhtMane = null;
  TorrentEngine._empty() {}

  Stream<TorrentEngineProgress> get onProgress => ai.onProgress;

  static Future<TorrentEngine> createTorrentEngine(HetiSocketBuilder builder, TorrentFile torrentfile, HetimaData downloadedData, {appid: "hetima_torrent_engine", haveAllData: false,
      int localPort: 18085, int globalPort: 18085, String globalIp: "0.0.0.0", String localIp: "0.0.0.0", int retryNum: 10, bool useUpnp: false, bool useDht: false, List<int> bitfield: null}) {
    TorrentEngine engine = new TorrentEngine._empty();
    return TrackerClient.createTrackerClient(builder, torrentfile).then((TrackerClient trackerClient) {
      engine._builder = builder;
      engine._trackerClient = trackerClient;
      engine._torrentClientManager = new TorrentClientManager(builder);
      //
      engine._upnpPortMapClient = new UpnpPortMapHelper(builder, appid);
      engine.ai = new TorrentEngineAI(engine._trackerClient, engine._upnpPortMapClient);
      engine.ai.baseLocalAddress = localIp;
      engine.ai.baseLocalPort = localPort;
      engine.ai.baseGlobalPort = globalPort;
      engine.ai.baseNumOfRetry = retryNum;
      engine.ai.usePortMap = useUpnp;
      engine.ai.useDht = useDht;
      engine.ai.baseGlobalIp = globalIp;

      //
      List<int> reserved = [0, 0, 0, 0, 0, 0, 0, 0];
      if (useDht == true) {
        reserved = [0, 0, 0, 0, 0, 0, 0, 0x01];
      }

      engine._torrentClient = new TorrentClient(
          builder, trackerClient.peerId, trackerClient.infoHash, torrentfile.info.pieces, torrentfile.info.piece_length, torrentfile.info.files.dataSize, downloadedData,
          ai: engine.ai, haveAllData: haveAllData, bitfield: bitfield, reserved: reserved);

      return engine;
    });
  }

  bool _isGO = false;
  bool get isGo => _isGO;

  Future start({usePortMap: false}) {
    ai.usePortMap = usePortMap;
    return ai.start(_torrentClient).then((v) {
      _isGO = true;
      return v;
    }).catchError((e) {
      throw e;
    });
  }

  Future stop() {
    return ai.stop().whenComplete(() {
      _isGO = false;
    });
  }
}

class TorrentEngineProgress {
  int _downloadSize = 0;
  int _fileSize = 0;
  int _numOfPeer = 0;
  String _failureReason = "";
  int get downloadSize => _downloadSize;
  int get fileSize => _fileSize;
  int get numOfPeer => _numOfPeer;
  String get trackerFailureReason => _failureReason;
  bool get trackerIsOk => _failureReason.length == 0;

  void update(TrackerClient tracker, TorrentClient torrent) {
    _downloadSize = torrent.targetBlock.rawHead.numOfOn(true) * torrent.targetBlock.blockSize;
    _fileSize = torrent.targetBlock.dataSize;
    _numOfPeer = torrent.rawPeerInfos.numOfPeerInfo();
    _failureReason = tracker.failedReason;
  }

  String toString() {
    return "progress:${100*downloadSize/fileSize}, numOfPeer:${numOfPeer}, tracker:${trackerFailureReason}";
  }
}

