library hetimatorrent.extra.torrentengine;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import 'torrentengineai.dart';
import 'torrentengineai_protmap.dart';

class TorrentEngineTorrent {
  TorrentClient _torrentClient = null;
  TrackerClient _trackerClient = null;
  TorrentClient get torrentClient => _torrentClient;
  TrackerClient get trackerClient => _trackerClient;
  TorrentEngineAI ai = null;
  Stream<TorrentEngineProgress> get onProgress => ai.onProgress;
  TorrentEngineTorrent._e() {}
  List<int> _infoHash = [];
  List<int> get infoHash => new List.from(_infoHash);

  static Future<TorrentEngineTorrent> createEngioneTorrent(TorrentEngine engine, TorrentFile torrentfile, HetimaData downloadedData,
      {haveAllData: false, int localPort: 18085, int globalPort: 18085, List<int> bitfield: null, useDht: false}) {
    TorrentEngineTorrent engineTorrent = new TorrentEngineTorrent._e();
    return TrackerClient.createTrackerClient(engine._builder, torrentfile).then((TrackerClient trackerClient) {
      engineTorrent._trackerClient = trackerClient;
      engineTorrent.ai = new TorrentEngineAI(trackerClient, engine._dhtClient, useDht);

      //
      List<int> reserved = [0, 0, 0, 0, 0, 0, 0, 0];
      if (useDht == true) {
        reserved = [0, 0, 0, 0, 0, 0, 0, 0x01];
      }

      engineTorrent._infoHash.addAll(trackerClient.infoHash);
      engineTorrent._torrentClient = new TorrentClient(
          engine._builder, trackerClient.peerId, trackerClient.infoHash, torrentfile.info.pieces, torrentfile.info.piece_length, torrentfile.info.files.dataSize, downloadedData,
          ai: engineTorrent.ai, haveAllData: haveAllData, bitfield: bitfield, reserved: reserved);

      return engineTorrent;
    });
  }
  
  Future startTorrent(TorrentEngine engine) {
    return ai.start(engine._torrentClientManager, _torrentClient);
  }

  Future stopTorrent() {
    return ai.stop();
  }
}

class TorrentEngine {
  TorrentClientManager _torrentClientManager = null;
  KNode _dhtClient = null;
  UpnpPortMapHelper _upnpPortMapClient = null;
  HetiSocketBuilder _builder = null;

  HetiSocketBuilder get socketBuilder => _builder;
  UpnpPortMapHelper get upnpPortMapClient => _upnpPortMapClient;
  TorrentEngineAIPortMap _portMapAI = null;

  int get localPort => _torrentClientManager.localPort;
  String get localIp => _torrentClientManager.localIp;
  int get globalPort => _torrentClientManager.globalPort;
  String get globalIp => _torrentClientManager.globalIp;

  bool _useUpnp = false;
  bool get useUpnp => _useUpnp;
  bool _useDht = false;
  bool get useDht => _useDht;
  void resetFlag(bool useUpnp, bool useDht) {
    _useUpnp = useUpnp;
    _useDht = useDht;
  }
  
  List<TorrentEngineTorrent> _torrents = [];
  Future<TorrentEngineTorrent> addTorrent(TorrentFile torrentfile, HetimaData downloadedData,
      {haveAllData: false, List<int> bitfield: null}) {
    return TorrentEngineTorrent
        .createEngioneTorrent(this, torrentfile, downloadedData, haveAllData: haveAllData, localPort: localPort, globalPort: globalPort, bitfield: bitfield, useDht: _useDht)
        .then((TorrentEngineTorrent engine) {
      if(null != getTorrent(engine._infoHash)) {
        throw {"message":"already add"};
      }
      _torrents.add(engine);
      return engine;
    });
  }

  void removeTorrent(TorrentEngineTorrent t) {
     _torrents.remove(t);
  }

  int numOfTorrent() {
     return _torrents.length;
  }

  TorrentEngineTorrent getTorrent(List<int> infoHash) {
    for (TorrentEngineTorrent tt in _torrents) {
      List<int> dd = tt.infoHash;
      bool ok = true;
      for (int i = 0; i < infoHash.length; i++) {
        if (dd[i] != infoHash[i]) {
          ok = false;
          break;
        }
      }
      if(ok == true) {
        return tt;
      }
    }
    return null;
  }

  TorrentEngine(HetiSocketBuilder builder,
      {appid: "hetima_torrent_engine", int localPort: 18085, int globalPort: 18085, String globalIp: "0.0.0.0", String localIp: "0.0.0.0", int retryNum: 10, 
        bool useUpnp: false, bool useDht: false}) {
    this._builder = builder;
    this._torrentClientManager = new TorrentClientManager(builder);
    this._upnpPortMapClient = new UpnpPortMapHelper(builder, appid);
    this._portMapAI = new TorrentEngineAIPortMap(upnpPortMapClient);
    this._useUpnp = useUpnp;
    this._useDht = useDht;
    this._dhtClient = new KNode(builder, verbose:false);
    this._dhtClient.onGetPeerValue.listen((KGetPeerValue value) {
      TorrentEngineTorrent t = getTorrent(value.infoHash.value);
      print("<=1==> ${value.ipAsString}:${value.port}");
      if(t != null) {
        print("<=2==> ${value.ipAsString}:${value.port}");
        t._torrentClient.putTorrentPeerInfoFromTracker(value.ipAsString, value.port);
      }
    });
  }

  addBootNode(String ip, int port) {
    if(ip != null && port != null) {
      _dhtClient.addBootNode(ip, port);
    }
  }

  bool _isStart = false;
  bool get isStart => _isStart;

  Future start() {
    _portMapAI.usePortMap = _useUpnp;
    return _portMapAI.start(_torrentClientManager, this._dhtClient).then((_) {
      _isStart = true;
    });
  }

  Future stop() {
    return _portMapAI.stop().whenComplete(() {
      _isStart = false;
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
