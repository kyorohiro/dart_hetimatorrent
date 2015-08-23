library hetimatorrent.extra.torrentengine.ai.portmap;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentai_basic.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import '../client/torrentclient_manager.dart';
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
  KNode _dhtClient = null;
  UpnpPortMapHelper _upnpPortMapClient = null;

  TorrentEngineAIPortMap(UpnpPortMapHelper upnpPortMapClient) {
    this._upnpPortMapClient = upnpPortMapClient;
  }

  Future start(TorrentClientManager manager, KNode dhtClient) {
    this._manager = manager;
    this._dhtClient = dhtClient;

    return _startTorrent(this._manager).then((_) {
      isStart = true;
      _upnpPortMapClient.clearSearchedRouterInfo();
    });
  }

  Future stop() {
    return this._manager.stop().then((_) {
      isStart = false;
      List<Future> r = [];
      if (usePortMap == true) {
        r.add(_upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter:false,newProtocol:UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP));
        r.add(_upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter:false,newProtocol:UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_UDP));
      }
      //if (useDht == true) {
        r.add(_dhtClient.stop());        
     // }
      return Future.wait(r);
    });
  }

  Future _startTorrent(TorrentClientManager manager) {
    int retry = 0;
    a(dynamic d) {
      return manager.start(baseLocalAddress, baseLocalPort + retry, baseGlobalIp, baseGlobalPort + retry).then((_) {
        return _dhtClient.start(ip:baseLocalAddress, port:baseLocalPort + retry).then((_){
          if (usePortMap == true) {
            return _startPortMap().then((_) {
              manager.globalPort = _upnpPortMapClient.externalPort;
            }).catchError((e) {
              manager.globalPort = manager.localPort;
              throw e;
            }).then((_) {
              return _upnpPortMapClient.startGetExternalIp(reuseRouter: true).then((List<StartGetExternalIp> ips) {
                manager.globalIp = ips.first.externalIp;
              }).catchError((e) {
                ;
              });
            });
          } else {
            manager.globalPort = manager.localPort;
          }
        });
      }).catchError((e) {
        if (retry < baseNumOfRetry) {
          retry++;
          List<Future> r = [];
          if (manager.isStart) {
            r.add(manager.stop());
          }
          
          if(_dhtClient.isStart) {
            r.add(_dhtClient.stop());
          }

          if(r.length > 0) {
            return Future.wait(r).then(a);
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
    _upnpPortMapClient.localIp = _manager.localIp;
    _upnpPortMapClient.localPort = _manager.localPort;
    return _upnpPortMapClient.startPortMap(reuseRouter: true,newProtocol:UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP).then((StartPortMapResult r){
      return _upnpPortMapClient.startPortMap(reuseRouter: true,newProtocol:UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_UDP);
    }).catchError((e){
      List<Future> r = [];
      r.add(_upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter:false,newProtocol:UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP));
      r.add(_upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter:false,newProtocol:UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_UDP));
      return Future.wait(r).then((_){
        throw e;
      });
    });
  }
}
