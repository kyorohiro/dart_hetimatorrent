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

    List<Future> v = new List(2);
    v[0] = portMapHelder.getPortMapInfo(portMapHelder.appid).then((GetPortMapInfoResult r) {
      if (r.infos.length > 0 && r.infos[0].externalPort.length != 0) {
        int port = int.parse(r.infos[0].externalPort);
        portMapHelder.deleteAllPortMap([port]);
      }
    }).catchError((e) {
      ;
    });

    v[1] = trackerServer.stop();
    return Future.wait(v);
  }

  Future startTracker(String localIP, int localPort, int globalPort) {
    trackerServer.address = localIP;
    trackerServer.port = localPort;
    return trackerServer.start().then((StartResult r) {
      if (upnpIsUse == true) {
        portMapHelder.basePort = globalPort;
        portMapHelder.numOfRetry = 0;
        portMapHelder.localAddress = localIP;
        portMapHelder.localPort = localPort;

        return portMapHelder.startGetExternalIp().then((_) {}).catchError((e) {}).then((_) {
          return portMapHelder.startPortMap().then((_) {
            trackerServer.trackerAnnounceAddressForTorrentFile = "http://${portMapHelder.externalIp}:${portMapHelder.externalPort}/announce";
            return [trackerServer.address, "${trackerServer.port}"];
          });
        });
      } else {
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
