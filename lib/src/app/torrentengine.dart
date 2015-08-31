library hetimatorrent.extra.torrentengine;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import 'torrentengineai_boot.dart';
import 'torrentengine_torrent.dart';

class TorrentEngine {
  UpnpPortMapHelper _upnpPortMapClient = null;
  HetimaSocketBuilder _builder = null;
  HetimaSocketBuilder get builder => _builder;
  UpnpPortMapHelper get upnpPortMapClient => _upnpPortMapClient;

  TorrentClientManager _torrentClientManager = null;
  TorrentClientManager get torrentClientManager => _torrentClientManager;

  KNode _dhtClient = null;
  KNode get dhtClient => _dhtClient;
  List<TorrentEngineTorrent> _torrents = [];
  List<TorrentEngineTorrent> get torrents => new List.from(_torrents);


  TorrentEngineAIPortMap _portMapAI = null;

  int get localPort => _torrentClientManager.localPort;
  String get localIp => _torrentClientManager.localIp;
  int get globalPort => _torrentClientManager.globalPort;
  String get globalIp => _torrentClientManager.globalIp;

  bool _useUpnp = false;
  bool get useUpnp => _useUpnp;
  bool _useDht = false;
  bool get useDht => _useDht;
  bool _verbose = false;
  bool get verbose => _verbose;


  TorrentEngine(HetimaSocketBuilder builder, 
      {appid: "hetima_torrent_engine", 
       int localPort: 18085, int globalPort: 18085,
       String globalIp: "0.0.0.0", String localIp: "0.0.0.0", 
       int retryNum: 5, bool useUpnp: false, bool useDht: false, 
       bool verbose: false}) {
    this._builder = builder;
    this._torrentClientManager = new TorrentClientManager(builder, verbose: verbose);
    this._upnpPortMapClient = new UpnpPortMapHelper(builder, appid, verbose: verbose);
    this._portMapAI = new TorrentEngineAIPortMap(upnpPortMapClient);
    this._useUpnp = useUpnp;
    this._useDht = useDht;
    this._dhtClient = new KNode(builder, verbose: verbose);
    this._verbose = verbose;
    this._dhtClient.onGetPeerValue.listen((KGetPeerValue value) {
      TorrentEngineTorrent t = getTorrent(value.infoHash.value);
      if (t != null) {
        log("<=1==> ${value.ipAsString}:${value.port}");
        t.torrentClient.putTorrentPeerInfoFromTracker(value.ipAsString, value.port);
      }
    });
  }

  void resetFlag(bool useUpnp, bool useDht) {
    _useUpnp = useUpnp;
    _useDht = useDht;
  }


  Future<TorrentEngineTorrent> addTorrent(TorrentFile torrentfile, HetimaData downloadedData, {haveAllData: false, List<int> bitfield: null}) {
    return TorrentEngineTorrent
        .createEngioneTorrent(this, torrentfile, downloadedData, haveAllData: haveAllData, localPort: localPort, globalPort: globalPort, bitfield: bitfield, useDht: _useDht)
        .then((TorrentEngineTorrent engine) {
      if (null != getTorrent(engine.rawinfoHash)) {
        throw {"message": "already add"};
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
      if (ok == true) {
        return tt;
      }
    }
    return null;
  }


  addBootNode(String ip, int port) {
    if (ip != null && port != null && useDht == true) {
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

  int get port => _torrentClientManager.localPort;
  bool get portMapIsOk => false;

  Future stop() {
    return _portMapAI.stop().whenComplete(() {
      _isStart = false;
    });
  }

  void log(String message) {
    if (_verbose) {
      print("## message");
    }
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
