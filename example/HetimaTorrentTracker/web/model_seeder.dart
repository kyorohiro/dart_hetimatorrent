library app.mainview.model.seeder;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class SeederModel {
  TorrentClient _client = null;
  UpnpPortMapHelper _portMapHelder = null;

  String localIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
  bool useUpnp = false;

  Future start(TorrentFile torrentFile, HetimaData seed) {
    return TorrentClient.create(new HetiSocketBuilderChrome(), PeerIdCreator.createPeerid("seeder"), torrentFile, seed).then((TorrentClient client) {
      _client = client;
      client.localAddress = localIp;
      client.port = localPort;
      return client.start();
    }).then((_) {
      if (useUpnp == true) {
        _portMapHelder = new UpnpPortMapHelper(new HetiSocketBuilderChrome(), "HetimaTorrentTracker");
        _portMapHelder.basePort = globalPort;
        _portMapHelder.numOfRetry = 0;
        return _portMapHelder.startPortMap().then((StartPortMapResult r) {
          return null;
        });
      } else {
        return new Future(() {
          return null;
        });
      }
    }).catchError((e) {
      if (_client != null) {
        _client.stop();
        _client = null;
        _portMapHelder = null;
      }
      throw e;
    });
  }

  Future stop() {
    return new Future(() {
      if (_client != null) {
        _client.stop();
        _client = null;
      }
      if (_portMapHelder != null) {
        return _portMapHelder.getPortMapInfo("HetimaTorrentTracker").then((GetPortMapInfoResult result) {
          List<int> deleteExternalPortList = [];
          for (PortMapInfo info in result.infos) {
            try {
              deleteExternalPortList.add(int.parse(info.externalPort));
            } catch (e) {
              ;
            }
          }
          return _portMapHelder.deleteAllPortMap(deleteExternalPortList);
        });
      } 
    });
  }
}
