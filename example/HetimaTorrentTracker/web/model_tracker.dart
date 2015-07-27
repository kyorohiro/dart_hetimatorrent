library app.trackermodel;

import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class TrackerModel {
  bool upnpIsUse = false;
  String selectKey = null;

///
  TrackerServer trackerServer = new TrackerServer(new HetiSocketBuilderChrome());
  UpnpPortMapHelper portMapHelder = new UpnpPortMapHelper(new HetiSocketBuilderChrome(), "HetimaTorrentTracker");

  void removeInfoHashFromTracker(List<int> removeHash) {
    trackerServer.removeInfoHash(PercentEncode.decode(selectKey));
  }

  void addInfoHashFromTracker(TorrentFile f) {
    trackerServer.addInfoHash(f);
  }

  Future stopTracker() {
    // clear
    trackerServer.trackerAnnounceAddressForTorrentFile = "";
    portMapHelder.clearSearchedRouterInfo();
    List<Future> v = new List(2);
    v[0] = portMapHelder.getPortMapInfo(target:portMapHelder.appid,reuseRouter:true).then((GetPortMapInfoResult r) {
      if (r.infos.length > 0 && r.infos[0].externalPort.length != 0) {
        int port = int.parse(r.infos[0].externalPort);
        portMapHelder.deleteAllPortMap([port],reuseRouter:true);
      }
    }).catchError((e) {
      ;
    });

    v[1] = trackerServer.stop();
    return Future.wait(v);
  }

  Future startTracker(String localIP, int localPort, String globalAddress, int globalPort) {
    trackerServer.address = localIP;
    trackerServer.port = localPort;
    return trackerServer.start().then((StartResult r) {
      if (upnpIsUse == true) {
        portMapHelder.basePort = globalPort;
        portMapHelder.numOfRetry = 0;
        portMapHelder.localAddress = localIP;
        portMapHelder.localPort = localPort;

        portMapHelder.clearSearchedRouterInfo();
        return portMapHelder.startGetExternalIp(reuseRouter:true).then((_) {}).catchError((e) {}).then((_) {
          return portMapHelder.startPortMap(reuseRouter:true).then((_) {
            trackerServer.trackerAnnounceAddressForTorrentFile = "http://${portMapHelder.externalIp}:${portMapHelder.externalPort}/announce";
            return [trackerServer.address, "${trackerServer.port}"];
          });
        });
      } else {
        trackerServer.trackerAnnounceAddressForTorrentFile = "http://${globalAddress}:${globalPort}/announce";
        return [trackerServer.address, "${trackerServer.port}"];
      }
    }).catchError((e) {
      print("error ${e}");
      return stopTracker().whenComplete((){
        throw e;
      });
    });
  }

  int getNumOfPeer(List<int> infoHash) {
    return trackerServer.numOfPeer(infoHash);
  }
}
