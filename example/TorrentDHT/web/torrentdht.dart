import 'dart:async';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'dart:html';

ButtonElement startButton = querySelector("#startButton");
ButtonElement stopButton = querySelector("#stopButton");
Element loading = querySelector("#loadingButton");
DivElement localIpContainer = querySelector("#localipContainer");
InputElement localAddress = querySelector("#localAddress");
DivElement messageContainer = querySelector("#messageContainer");
InputElement initNodeIp = querySelector("#initNodeIp");
InputElement initNodePort = querySelector("#initNodePort");
void main() {
  DHT dht = new DHT();
  startButton.onClick.listen((_) {
    new Future(() {
      startButton.style.display = "none";
      loading.style.display = "block";
      messageContainer.children.clear();
      dht.addNode(initNodeIp.value, int.parse(initNodePort.value));
      dht.start(localAddress.value).then((_) {
        loading.style.display = "none";
        stopButton.style.display = "block";
      });
    }).catchError((e) {
      loading.style.display = "none";
      startButton.style.display = "block";
      messageContainer.children.add(new Element.html("<div>error</div>"));
    });
  });

  stopButton.onClick.listen((_) {
    stopButton.style.display = "none";
    loading.style.display = "block";
    messageContainer.children.clear();
    dht.stop().then((_) {
      loading.style.display = "none";
      startButton.style.display = "block";
    }).catchError((e) {
      loading.style.display = "none";
      stopButton.style.display = "block";
      messageContainer.children.add(new Element.html("<div>error</div>"));
    });
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
  Future start(String ip) {
    return node.start(ip: ip).then((_) {
      node.onGetPeerValue.listen((KGetPeerValue v) {
        print("---onGetPeerValue ${v.ipAsString} ${v.port} ${v.infoHashAsString} ");
      });
    });
  }

  Future stop() {
    return node.stop();
  }

  addNode(String ip, int port) {
    node.addNodeFromIPAndPort(ip, port);
  }
}
