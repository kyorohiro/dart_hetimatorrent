library hetimatorrent.dht.knode;

import 'dart:core';
import 'dart:async';
import 'dart:math';


abstract class KNodeComm {
  Future start();
  Future stop();
  Future send(String ip, int port, List<int> bytes);
  Stream<KNodeCommReceive> onReceive;
}

class KNodeCommReceive {
  
}

class KNodeCommSimuMane {
  KNodeCommSimuMane._em();
  static KNodeCommSimuMane _mane = new KNodeCommSimuMane._em();
  static KNodeCommSimuMane get instance => _mane;

  Map<String, KNodeCommSimu> nodes = {};
}

class KNodeCommSimu extends KNodeComm {
  String _ip = "";
  int _port;
  
  String get ip => _ip;
  int get port => _port;

  KNodeComm(String ip, int port) {
    this._ip = ip;
    this._port = port;
  }
  Future start() {
    return new Future(() {
      if (KNodeCommSimuMane.instance.nodes.containsKey("${ip}:${port}")) {
        throw {"":"already start"};
      }
      KNodeCommSimuMane.instance.nodes["${ip}:${port}"] = this;
    });
  }

  Future stop() {
    return new Future((){
      KNodeCommSimuMane.instance.nodes["${ip}:${port}"] = this;      
    });
  }

  Future send(String ip, int port, List<int> bytes) {
    return new Future((){
      if (KNodeCommSimuMane.instance.nodes.containsKey("${ip}:${port}")) {
        throw {"":"not found"};
      }
      return KNodeCommSimuMane.instance.nodes["${ip}:${port}"].receive(bytes);
    });
  }
  
  StreamController _receiveMessage = new StreamController.broadcast();
  Stream<KNodeCommReceive> get onReceive => _receiveMessage.stream;

  Future receive(List<int> bytes) {
    return new Future(() {
      _receiveMessage.add(new KNodeCommReceive());      
    });
  }
}

class KNode {}
