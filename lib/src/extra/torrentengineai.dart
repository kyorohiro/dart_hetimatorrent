library hetimatorrent.extra.torrentengine.ai;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentaibasic.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
//import 'torrentengineai.dart';

class TorrentEngineAI extends TorrentAI {
  TorrentAIBasic basic = new TorrentAIBasic();
  bool usePortMap = false;
  bool isGo = false;

  String baseLocalAddress = "0.0.0.0";
  String baseGlobalIp = "0.0.0.0";
  int baseLocalPort = 18080;
  int baseGlobalPort = 18080;
  int baseNumOfRetry = 10;

  TorrentClient _torrent = null;
  TrackerClient _tracker = null;
  UpnpPortMapHelper _upnpPortMapClient = null;

  StreamController<TorrentEngineAIProgress> _progressStream = new StreamController.broadcast();
  Stream<TorrentEngineAIProgress> get onProgress => _progressStream.stream;
  TorrentEngineAIProgress _progressCash = new TorrentEngineAIProgress();

  TorrentEngineAI(TrackerClient tracker, UpnpPortMapHelper upnpPortMapClient) {
    this._tracker = tracker;
    this._upnpPortMapClient = upnpPortMapClient;
  }

  Future onRegistAI(TorrentClient client) {
    this._torrent = client;
    basic.onRegistAI(client);
    return new Future(() {
      
    });
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
    _progressCash._update(_tracker,_torrent);
    _progressStream.add(_progressCash);
    if (isGo != true) {
      return new Future(() {
        print("Empty AI tick : ${client.peerId}");
      });
    } else {
      return basic.onTick(client);
    }
  }

  Future go() {
    return _startTorrent().then((_) {
      isGo = true;
      _startTracker(1).catchError((e) {});
    });
  }

  Future stop() {
    return this._torrent.stop().then((_) {
      if (usePortMap == true) {
        return _upnpPortMapClient.deletePortMapFromAppIdDesc().catchError((e) {});
      }
    }).whenComplete(() {
      isGo = false;
    });
  }

  Future _startTorrent() {
    int retry = 0;
    a() {
      return this._torrent.start(baseLocalAddress, baseLocalPort + retry, baseGlobalIp, baseGlobalPort+ retry).then((_) {
        if (usePortMap == true) {
          return _startPortMap().then((_) {
            _torrent.globalPort = _upnpPortMapClient.externalPort;
          }).catchError((e) {
            _torrent.globalPort = _torrent.localPort;
            throw e;
          }).then((_) {
            return _upnpPortMapClient.startGetExternalIp().then((StartGetExternalIp ip) {
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
          if(_torrent.isStart) {
            return _torrent.stop().then((_){
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
    return _upnpPortMapClient.startPortMap();
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
      if (isGo == false) {
        return null;
      }
      _tracker.event = TrackerClient.EVENT_STARTED;
      _tracker.peerport = _torrent.globalPort;
      if (localNetworkIp(_torrent.globalIp)) {
        _tracker.optIp = null;
      } else {
        _tracker.optIp = _torrent.globalIp;
      }
      return _tracker.requestWithSupportRedirect().then((TrackerRequestResult r) {
        for (TrackerPeerInfo info in r.response.peers) {
          _torrent.putTorrentPeerInfoFromTracker(info.ipAsString, info.port);
        }
        _startTracker(r.response.interval);
      }).catchError((e){
        //
        // todo
        _startTracker(60);
      });
    });
  }

}

class TorrentEngineAIProgress {
  int _downloadSize = 0;
  int _fileSize = 0;
  int _numOfPeer = 0;
  int get downloadSize => _downloadSize;
  int get fileSize => _fileSize;
  int get numOfPeer => _numOfPeer;
 void  _update(TrackerClient tracker, TorrentClient torrent) {
    _downloadSize = torrent.targetBlock.rawHead.numOfOn(true) * torrent.targetBlock.blockSize;
    _fileSize = torrent.targetBlock.dataSize;
    _numOfPeer = torrent.rawPeerInfos.numOfPeerInfo();
  }
}
