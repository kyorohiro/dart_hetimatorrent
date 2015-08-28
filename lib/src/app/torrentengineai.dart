library hetimatorrent.extra.torrentengine.ai;

import 'dart:async';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentai_basic.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import '../client/torrentclient_manager.dart';
import '../dht/knode.dart';
import '../dht/kid.dart';

class TorrentEngineAI extends TorrentAI {
  TorrentAIBasic basic = null;
  bool _useDht = false;
  bool get useDht => _useDht;
  bool isGo = false;

  TorrentClient _torrent = null;
  TrackerClient _tracker = null;
  KNode _dht = null;

  StreamController<TorrentEngineProgress> _progressStream = new StreamController.broadcast();
  Stream<TorrentEngineProgress> get onProgress => _progressStream.stream;
  TorrentEngineProgress _progressCash = new TorrentEngineProgress();

  TorrentEngineAI(TrackerClient tracker, KNode dhtClient, bool useDht) {
    this._tracker = tracker;
    this._useDht = useDht;
    this._dht = dhtClient;
    this.basic = new TorrentAIBasic(useDht: useDht);
  }

  @override
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) async {
    if (isGo == true) {
      if (message.id == TorrentMessage.SIGN_PORT) {
        if (useDht == true) {
          TMessagePort messagePort = message;
          this._dht.addBootNode(info.ip, messagePort.port);
        }
      }
      return basic.onReceive(client, info, message);
    }
  }

  @override
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal signal) async {
    if (isGo == true) {
      return basic.onSignal(client, info, signal);
    }
  }

  @override
  Future onTick(TorrentClient client) async {
    _progressCash.update(_tracker, _torrent);
    _progressStream.add(_progressCash);
    if (isGo == true) {
      return basic.onTick(client);
    }
  }

  Future start(TorrentClientManager manager, TorrentClient torrentClient) {
    this._torrent = torrentClient;
    _tracker.peerport = manager.globalPort;
    torrentClient.startWithoutSocket(manager.localIp, manager.localPort, manager.globalIp, manager.globalPort);
    manager.addTorrentClientWithDelegationToAccept(torrentClient);
    if (useDht == true) {
      _dht.startSearchValue(new KId(_tracker.infoHash), _torrent.globalPort);
    }

    isGo = true;
    return _startTracker(1).catchError((e) {});
  }

  Future stop() async {
    await this._torrent.stop();
    isGo = false;
    if (useDht == true) {
      await _dht.stopSearchPeer(new KId(_tracker.infoHash)).catchError((e) {});
    }
    return await _startTracker(0).catchError((e) {});
  }

  bool localNetworkIp(String ip) {
    if (ip.startsWith(new RegExp("127\.|0\.|10\.|192\."))) {
      return true;
    } else {
      return false;
    }
  }

  Future _startTracker(int intervalSec) async {
    await new Future.delayed(new Duration(seconds: intervalSec));
    if (false == isGo) {
      _tracker.event = TrackerClient.EVENT_STOPPED;
    } else if (_torrent.targetBlock.haveAll()) {
      _tracker.event = TrackerClient.EVENT_COMPLETED;
    } else {
      _tracker.event = TrackerClient.EVENT_STARTED;
    }

    _tracker.peerport = _torrent.globalPort;
    if (localNetworkIp(_torrent.globalIp)) {
      _tracker.optIp = null;
    } else {
      _tracker.optIp = _torrent.globalIp;
    }
    _tracker.downloaded = _torrent.downloaded;
    _tracker.uploaded = _torrent.uploaded;
    try {
      TrackerRequestResult r = await _tracker.requestWithSupportRedirect();
      for (TrackerPeerInfo info in r.response.peers) {
        _torrent.putTorrentPeerInfoFromTracker(info.ipAsString, info.port);
      }
      if (isGo == true) {
        if(r.response.interval != null) {
          _startTracker(r.response.interval);
        } else {
          throw "";
        }
      }
    } catch (e) {
      if (isGo == true) {
        _startTracker(60 * 5);
      }
    }
  }
}
