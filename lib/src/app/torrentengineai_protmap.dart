library hetimatorrent.extra.torrentengine.ai.portmap;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentai_basic.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import '../client_new/torrentclient_manager.dart';
import 'torrentengineai_protmap.dart';

//import 'torrentengineai.dart';

class TorrentEngineAIPortMap {
  bool usePortMap = false;
  bool useDht = false;
  bool isStart = false;

  String baseLocalAddress = "0.0.0.0";
  String baseGlobalIp = "0.0.0.0";
  int baseLocalPort = 18080;
  int baseGlobalPort = 18080;
  int baseNumOfRetry = 10;

  TorrentClientManager _manager = null;
  UpnpPortMapHelper _upnpPortMapClient = null;

  TorrentEngineAIPortMap(UpnpPortMapHelper upnpPortMapClient) {
    this._upnpPortMapClient = upnpPortMapClient;
  }

  Future start(TorrentClientManager manager) {
    this._manager = manager;

    return _startTorrent(this._manager).then((_) {
      isStart = true;
      _upnpPortMapClient.clearSearchedRouterInfo();
    });
  }

  Future stop() {
    return this._manager.stop().then((_) {
      isStart = false;
      if (usePortMap == true) {
        return _upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter: true).catchError((e) {});
      }
    });
  }

  Future _startTorrent(TorrentClientManager manager) {
    int retry = 0;
    a(dynamic d) {
      return manager.start(baseLocalAddress, baseLocalPort + retry, baseGlobalIp, baseGlobalPort + retry).then((_) {
        if (usePortMap == true) {
          return _startPortMap().then((_) {
            manager.globalPort = _upnpPortMapClient.externalPort;
          }).catchError((e) {
            manager.globalPort = manager.localPort;
            throw e;
          }).then((_) {
            return _upnpPortMapClient.startGetExternalIp(reuseRouter: true).then((StartGetExternalIp ip) {
              manager.globalIp = ip.externalIp;
            }).catchError((e) {
              ;
            });
          });
        } else {
          manager.globalPort = manager.localPort;
        }
      }).catchError((e) {
        if (retry < baseNumOfRetry) {
          retry++;
          if (manager.isStart) {
            return manager.stop().then(a);
          } else {
            return a(0);
          }
        } else {
          throw e;
        }
      });
    }
    return a(0);
  }

  Future _startPortMap() {
    _upnpPortMapClient.numOfRetry = 0;
    _upnpPortMapClient.basePort = _manager.localPort;
    _upnpPortMapClient.localAddress = _manager.localIp;
    _upnpPortMapClient.localPort = _manager.localPort;
    return _upnpPortMapClient.startPortMap(reuseRouter: true);
  }
}
