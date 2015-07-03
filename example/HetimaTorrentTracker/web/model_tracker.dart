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

    portMapHelder.getPortMapInfo(portMapHelder.appid).then((GetPortMapInfoResult r) {
      if (r.infos.length > 0 && r.infos[0].externalPort.length != 0) {
        int port = int.parse(r.infos[0].externalPort);
        portMapHelder.deleteAllPortMap([port]);
      }
    }).catchError((e) {
      ;
    });

    return trackerServer.stop();
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

        portMapHelder.startGetExternalIp().then((_) {}).catchError((e) {}).whenComplete(() {
          portMapHelder.startPortMap().then((_) {
            trackerServer.trackerAnnounceAddressForTorrentFile = "http://${portMapHelder.externalIp}:${portMapHelder.externalPort}/announce";
          }).catchError((e) {
            print("error ${e}");
          });
        });
      }
      return [trackerServer.address, "${trackerServer.port}"];
    });
  }

  int getNumOfPeer(List<int> infoHash) {
    return trackerServer.numOfPeer(infoHash);
  }
}
