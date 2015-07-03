library app.mainview.model.seeder;

import 'dart:async';
import 'dart:html' as html;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class SeederModel {
  TorrentClient client = null;
  UpnpPortMapHelper portMapHelder = new UpnpPortMapHelper(new HetiSocketBuilderChrome(), "HetimaTorrentTracker");

  String localIp = "0.0.0.0";
  int localPort = 18080;
  int globalPort = 18080;
  bool useUpnp = false;
  
  Future start(TorrentFile torrentFile, HetimaData seed) {
    return TorrentClient.create(new HetiSocketBuilderChrome(),
        PeerIdCreator.createPeerid("seeder"),
        torrentFile, seed).then((TorrentClient client){
      client.localAddress = localIp;
      client.port = localPort;
      return client.start();
    }).then((_){
      if(useUpnp == true) {
        portMapHelder.basePort = globalPort;
        portMapHelder.numOfRetry = 0;
        return portMapHelder.startPortMap().then((StartPortMapResult r) {
          return null;
        });
      } else {
        return new Future(() {
          return null;
        });
      }
    });
  }
}
