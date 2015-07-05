library hetimatorrent.extra.torrentengine.ai;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
//import 'torrentengineai.dart';


class TorrentEngineAI extends TorrentAI {
  TorrentAIBasic basic = new TorrentAIBasic();
  bool usePortMap = false;
  bool isGo = false;

  String baseLocalAddress = "0.0.0.0";
  int baseLocalPort = 18080;
  int baseGlobalPort = 18080;
  int baseNumOfRetry = 10;

  TorrentClient _torrent = null;
  TrackerClient _tracker = null;
  UpnpPortMapHelper _upnpPortMapClient = null;

  TorrentEngineAI(TorrentClient torrent, TrackerClient tracker, UpnpPortMapHelper upnpPortMapClient) {
    this._torrent = torrent;
    this._tracker = tracker;
    this._upnpPortMapClient = upnpPortMapClient;
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

  Future go() {
    return _startTorrent().then((_) {
      isGo = true;
      _startTracker(1).catchError((e){});
    });
  }

  Future stop() {
    return this._torrent.stop().then((_) {
      if (usePortMap == true) {
        return _upnpPortMapClient.deletePortMapFromAppIdDesc().catchError((e) {});
      }
    });
  }

  Future _startTorrent() {
    int retry = 0;
    a() {
      return this._torrent.start(baseLocalAddress, baseLocalPort + retry, baseGlobalPort).then((_) {
        if (usePortMap == true) {
          return _startPortMap().then((_) {
            _torrent.globalPort = _upnpPortMapClient.externalPort;
          }).catchError((e) {
            _torrent.globalPort = _torrent.localPort;
          });
        } else {
          _torrent.globalPort = _torrent.localPort;
        }
      }).catchError((e) {
        if (retry < baseNumOfRetry) {
          retry++;
          a();
        } else {
          throw e;
        }
      });
    }
    return a();
  }

  Future _startPortMap() {
    _upnpPortMapClient.numOfRetry = baseNumOfRetry;
    _upnpPortMapClient.basePort = baseGlobalPort;
    _upnpPortMapClient.localAddress = _torrent.localAddress;
    _upnpPortMapClient.localPort = _torrent.localPort;
    return _upnpPortMapClient.startPortMap();
  }

  Future _startTracker(int intervalSec) {
    return new Future.delayed(new Duration(seconds: intervalSec)).then((_) {
      if(isGo == false) {
        return null;
      }
      _tracker.event = TrackerClient.EVENT_STARTED;
      _tracker.peerport = _torrent.globalPort;
      return _tracker.request().then((TrackerRequestResult r) {
        for (TrackerPeerInfo info in r.response.peers) {
          _torrent.putTorrentPeerInfo(info.ipAsString, info.port);
        }
        _startTracker(r.response.interval);
      });
    });
  }
}
