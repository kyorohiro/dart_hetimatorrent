import 'dart:async';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'dart:html';

ButtonElement startButton = querySelector("#startButton");
ButtonElement stopButton = querySelector("#stopButton");
Element loading = querySelector("#loadingButton");
DivElement localIpContainer = querySelector("#localipContainer");
InputElement localAddress = querySelector("#localAddress");
InputElement localPort = querySelector("#localPort");
DivElement messageContainer = querySelector("#messageContainer");
InputElement initNodeIp = querySelector("#initNodeIp");
InputElement initNodePort = querySelector("#initNodePort");
ButtonElement logButton = querySelector("#logButton");

DivElement targetInfohash = querySelector("#targetInfohash");
ButtonElement startSearchButton = querySelector("#startSearchButton");
ButtonElement stopSearchButton = querySelector("#stopSearchButton");
Element loadingSearchButton= querySelector("#loadingSearchButton");
InputElement searchTarget = querySelector("#searchTarget");

void main() {
  DHT dht = new DHT();
  List<int> infoHash = [];
  startButton.onClick.listen((_) {
    new Future(() {
      startButton.style.display = "none";
      loading.style.display = "block";
      messageContainer.children.clear();
      dht.addNode(initNodeIp.value, int.parse(initNodePort.value));
      dht.start(localAddress.value, int.parse(localPort.value)).then((_) {
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

  logButton.onClick.listen((_) {
    messageContainer.children.clear();
    messageContainer.children.add(new Element.html("<div>${dht.log()}</dic>"));
  });

  (new HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<HetiNetworkInterface> interfaces) {
    localIpContainer.children.clear();
    for (HetiNetworkInterface interface in interfaces) {
      localIpContainer.children.add(new Element.html("<div>${interface.address} : ${interface.name}</div>"));
    }
  });

  searchTarget.onChange.listen((_) {
    File f = searchTarget.files.first;
    new Future(() {
      return TorrentFile.createFromTorrentFile(new HetimaFileToBuilder(new HetimaDataBlob(f))).then((TorrentFile f) {
        return f.createInfoSha1().then((List<int> ih) {
          infoHash.clear();
          infoHash.addAll(ih);
          targetInfohash.children.clear();
          targetInfohash.children.add(new Element.html("<div>${PercentEncode.encode(ih)}</div>"));
        });
      });
    }).catchError(() {
      messageContainer.children.clear();
      messageContainer.children.add(new Element.html("<div>Failed to load torrent file</dic>"));
    });
  });

  startSearchButton.onClick.listen((_) {
    startSearchButton.style.display = "none";
    stopSearchButton.style.display = "none";
    loadingSearchButton.style.display = "block";
    new Future((){
      return dht.addTarget(infoHash).then((_){
        startSearchButton.style.display = "none";
        stopSearchButton.style.display = "block";
        loadingSearchButton.style.display = "none";  
      });      
    }).catchError((e){
      startSearchButton.style.display = "block";
      stopSearchButton.style.display = "none";
      loadingSearchButton.style.display = "none";      
    });
  });
  
  stopSearchButton.onClick.listen((_){
    startSearchButton.style.display = "none";
    stopSearchButton.style.display = "none";
    loadingSearchButton.style.display = "block";
    new Future(() {
      return dht.rmTarget(infoHash).then((_){
        startSearchButton.style.display = "block";
        stopSearchButton.style.display = "none";
        loadingSearchButton.style.display = "none"; 
      });      
    }).catchError((e){
      startSearchButton.style.display = "none";
      stopSearchButton.style.display = "block";
      loadingSearchButton.style.display = "none";  
    });
  });
}

class DHT {
  KNode node = new KNode(new HetiSocketBuilderChrome(), verbose: true);
  Future start(String ip, int port) {
    return node.start(ip: ip, port: port).then((_) {
      node.onGetPeerValue.listen((KGetPeerValue v) {
        print("---onGetPeerValue ${v.ipAsString} ${v.port} ${v.infoHashAsString} ");
      });
    });
  }

  Future stop() {
    return node.stop();
  }

  addNode(String ip, int port) {
    node.addBootNode(ip, port);
  }

  Future addTarget(List<int> infoHash) {
    return node.startSearchValue(new KId(infoHash), 18080, getPeerOnly: true);
  }

  Future rmTarget(List<int> infoHash) {
    return node.stopSearchPeer(new KId(infoHash));
  }

  String log() {
    return node.rootingtable.toInfo().replaceAll("\n", "<br>");
  }
}

