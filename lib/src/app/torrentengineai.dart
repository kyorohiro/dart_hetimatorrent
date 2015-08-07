library hetimatorrent.extra.torrentengine.ai;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentai_basic.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import '../client/torrentclient_manager.dart';
//import 'torrentengineai.dart';

class TorrentEngineAI extends TorrentAI {
  TorrentAIBasic basic = new TorrentAIBasic();
  bool usePortMap = false;
  bool useDht = false;
  bool isGo = false;

//  int localPort = 18080;
//  int globalPort = 18080;

  TorrentClient _torrent = null;
  TrackerClient _tracker = null;

  StreamController<TorrentEngineProgress> _progressStream = new StreamController.broadcast();
  Stream<TorrentEngineProgress> get onProgress => _progressStream.stream;
  TorrentEngineProgress _progressCash = new TorrentEngineProgress();

  TorrentEngineAI(TrackerClient tracker) {
    this._tracker = tracker;
  }

  @override
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    if (isGo != true) {
      return new Future(() {
        print("Empty AI receive : ${message.id}");
      });
    } else {
      return basic.onReceive(client, info, message);
    }
  }

  @override
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal signal) {
    if (isGo != true) {
      return new Future(() {
        print("Empty AI signal : ${signal.id}");
      });
    } else {
      return basic.onSignal(client, info, signal);
    }
  }

  @override
  Future onTick(TorrentClient client) {
    _progressCash.update(_tracker, _torrent);
    _progressStream.add(_progressCash);
    if (isGo != true) {
      return new Future(() {
        print("Empty AI tick : ${client.peerId}");
      });
    } else {
      return basic.onTick(client);
    }
  }

  Future start(TorrentClientManager manager, TorrentClient torrentClient) {
    this._torrent = torrentClient;
    _tracker.peerport = manager.globalPort;
    torrentClient.startWithoutSocket(manager.localIp, manager.localPort, manager.globalIp, manager.globalPort);
    manager.addTorrentClient(torrentClient);
    isGo = true;
    return _startTracker(1).catchError((e) {});
  }

  Future stop() {
    return this._torrent.stop().then((_) {
      isGo = false;
    }).then((_) {
      return _startTracker(0).catchError((e) {});
    });
  }

  bool localNetworkIp(String ip) {
    if (ip.startsWith(new RegExp("127\.|0\.|10\.|192\."))) {
      return true;
    } else {
      return false;
    }
  }

  Future _startTracker(int intervalSec) {
    return new Future.delayed(new Duration(seconds: intervalSec)).then((_) {
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
      return _tracker.requestWithSupportRedirect().then((TrackerRequestResult r) {
        for (TrackerPeerInfo info in r.response.peers) {
          _torrent.putTorrentPeerInfoFromTracker(info.ipAsString, info.port);
        }
        if (isGo == true && r.response.interval != null) {
          _startTracker(r.response.interval);
        }
      }).catchError((e) {
        //
        // todo
        if (isGo == true) {
          _startTracker(30 * 5);
        }
      });
    });
  }
}
