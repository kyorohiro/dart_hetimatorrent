library hetimatorrent.extra.torrentengine.ai;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentai_basic.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import '../client_new/torrentclient_manager.dart';
//import 'torrentengineai.dart';

class TorrentEngineAI extends TorrentAI {
  TorrentAIBasic basic = new TorrentAIBasic();
  bool usePortMap = false;
  bool useDht = false;
  bool isGo = false;

  String baseLocalAddress = "0.0.0.0";
  String baseGlobalIp = "0.0.0.0";
  int baseLocalPort = 18080;
  int baseGlobalPort = 18080;
  int baseNumOfRetry = 10;

  TorrentClient _torrent = null;
  TrackerClient _tracker = null;
  UpnpPortMapHelper _upnpPortMapClient = null;

  StreamController<TorrentEngineProgress> _progressStream = new StreamController.broadcast();
  Stream<TorrentEngineProgress> get onProgress => _progressStream.stream;
  TorrentEngineProgress _progressCash = new TorrentEngineProgress();

  TorrentEngineDHTMane _dhtmane = null;
  TorrentEngineAI(TrackerClient tracker, UpnpPortMapHelper upnpPortMapClient, TorrentEngineDHTMane mane) {
    this._tracker = tracker;
    this._upnpPortMapClient = upnpPortMapClient;
    this._dhtmane = mane;
  }

  @override
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    if (isGo != true) {
      return new Future(() {
        print("Empty AI receive : ${message.id}");
      });
    } else {
      _dhtmane.onReceive(client, info, message);
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
      _dhtmane.onSignal(client, info, signal);
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
      _dhtmane.onTick(client);
      return basic.onTick(client);
    }
  }

  Future start(TorrentClient torrentClient) {
    this._torrent = torrentClient;
    return _startTorrent().then((_) {
      isGo = true;
      _upnpPortMapClient.clearSearchedRouterInfo();

      return new Future(() {
        if (useDht == true) {
          return _dhtmane.startDHT(useUpnp: usePortMap).then((a) {
            _dhtmane.startGetPeer(_torrent.infoHash, _torrent.globalPort);
            return a;
          });
        }
      }).then((_) {
        _startTracker(1).catchError((e) {});
      });
    });
  }

  Future stop() {
    return this._torrent.stop().then((_) {
      isGo = false;
      if (usePortMap == true) {
        return _upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter: true).catchError((e) {}).then((_) {
          return _dhtmane.stopDHT();
        });
      } else {
        return _dhtmane.stopDHT();
      }
    }).then((_) {
      return _startTracker(0).catchError((e) {});
    });
  }

  Future _startTorrent() {
    int retry = 0;
    a() {
      return this._torrent.start(baseLocalAddress, baseLocalPort + retry, baseGlobalIp, baseGlobalPort + retry).then((_) {
        if (usePortMap == true) {
          return _startPortMap().then((_) {
            _torrent.globalPort = _upnpPortMapClient.externalPort;
          }).catchError((e) {
            _torrent.globalPort = _torrent.localPort;
            throw e;
          }).then((_) {
            return _upnpPortMapClient.startGetExternalIp(reuseRouter: true).then((StartGetExternalIp ip) {
              _torrent.globalIp = ip.externalIp;
            }).catchError((e) {
              ;
            });
          });
        } else {
          _torrent.globalPort = _torrent.localPort;
        }
      }).catchError((e) {
        if (retry < baseNumOfRetry) {
          retry++;
          if (_torrent.isStart) {
            return _torrent.stop().then((_) {
              return a();
            });
          } else {
            return a();
          }
        } else {
          throw e;
        }
      });
    }
    return a();
  }

  Future _startPortMap() {
    _upnpPortMapClient.numOfRetry = 0;
    _upnpPortMapClient.basePort = _torrent.localPort;
    _upnpPortMapClient.localAddress = _torrent.localAddress;
    _upnpPortMapClient.localPort = _torrent.localPort;
    return _upnpPortMapClient.startPortMap(reuseRouter: true);
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
