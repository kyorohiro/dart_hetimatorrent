library hetimatorrent.extra.torrentengine.ai.portmap;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentclient_manager.dart';

class TorrentEngineAIPortMap {
  bool usePortMap = false;
  bool useDht = false;
  bool isStart = false;

  String baseLocalAddress = "0.0.0.0";
  String baseGlobalIp = "0.0.0.0";
  int baseLocalPort = 18080;
  int baseGlobalPort = 18080;
  int baseNumOfRetry = 3;

  TorrentClientManager _manager = null;
  KNode _dhtClient = null;
  UpnpPortMapHelper _upnpPortMapClient = null;

  TorrentEngineAIPortMap(UpnpPortMapHelper upnpPortMapClient) {
    this._upnpPortMapClient = upnpPortMapClient;
  }

  Future<bool> start(TorrentClientManager manager, KNode dhtClient) async {
    this._manager = manager;
    this._dhtClient = dhtClient;
    bool usePortMapIsOk = usePortMap;
    try {
      await _startTorrent(this._manager, usePortMap);
      isStart = true;
      return usePortMapIsOk;
    } catch (e) {
      if (usePortMap == false) {
        throw e;
      }
    }

    await _startTorrent(this._manager, false);
    isStart = true;
    return false;
  }

  Future stop() async {
    await this._manager.stop();
    isStart = false;
    List<Future> r = [];
    if (usePortMap == true) {
      r.add(_upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter: false, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP));
      r.add(_upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter: false, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_UDP));
    }
    r.add(_dhtClient.stop());
    return Future.wait(r);
  }

  Future _startTorrent(TorrentClientManager manager, bool usePortMap_t) async {
    int retry = 0;
    while (retry <= baseNumOfRetry) {
      try {
        await manager.start(baseLocalAddress, baseLocalPort + retry, baseGlobalIp, baseGlobalPort + retry);
        await _dhtClient.start(ip: baseLocalAddress, port: baseLocalPort + retry);
        manager.globalPort = manager.localPort;
        if (usePortMap_t == true) {
          await _startPortMap();
          manager.globalPort = _upnpPortMapClient.externalPort;

          List<StartGetExternalIp> ips = await _upnpPortMapClient.startGetExternalIp(reuseRouter: true);
          manager.globalIp = ips.first.externalIp;
        }
        return;
      } catch (e) {}
      retry++;

      List<Future> r = [];
      if (manager.isStart) {
        r.add(manager.stop());
      }
      if (_dhtClient.isStart) {
        r.add(_dhtClient.stop());
      }
      if (r.length > 0) {
        await Future.wait(r);
      }
    }
    throw "";
  }

  Future _startPortMap() async {
    _upnpPortMapClient.numOfRetry = 0;
    _upnpPortMapClient.basePort = _manager.localPort;
    _upnpPortMapClient.localIp = _manager.localIp;
    _upnpPortMapClient.localPort = _manager.localPort;

    List<Future> f = new List(2);
    f[0] = _upnpPortMapClient.startPortMap(reuseRouter: true, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP);
    f[1] = _upnpPortMapClient.startPortMap(reuseRouter: true, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_UDP);
    return Future.wait(f);
  }
}
