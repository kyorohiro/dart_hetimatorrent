import 'dart:async';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'dart:html';

ButtonElement startButton = querySelector("#startButton");
ButtonElement stopButton = querySelector("#stopButton");
Element loading = querySelector("#loadingButton");
DivElement localIpContainer = querySelector("#localipContainer");

void main() {
  startButton.onClick.listen((_) {
    startButton.style.display = "none";
    loading.style.display = "block";
    stopButton.style.display = "block";
  });

  stopButton.onClick.listen((_) {
    startButton.style.display = "block";
    stopButton.style.display = "none";
  });

  (new HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<HetiNetworkInterface> interfaces) {
    localIpContainer.children.clear();
    for (HetiNetworkInterface interface in interfaces) {
      localIpContainer.children.add(new Element.html("<div>${interface.address} : ${interface.name}</div>"));
    }
  });
}

class DHT {
  KNode node = new KNode(new HetiSocketBuilderChrome(), verbose: true);
  start(String ip) {
    return node.start(ip: ip).then((_) {


      // int torrentClientAccessPort = 18080;
      // KId torrentClientDownloadDataHash = new KId(new List.filled(20, 1));
      // node.startSearchPeer(torrentClientDownloadDataHash, torrentClientAccessPort);
      node.onGetPeerValue.listen((KGetPeerValue v) {
        print("---onGetPeerValue ${v.ipAsString} ${v.port} ${v.infoHashAsString} ");
      });
    });
  }

  stop() {
    return node.stop();
  }
  addNode(String ip, int port) {
    node.addNodeFromIPAndPort(ip, port);
  }
}
