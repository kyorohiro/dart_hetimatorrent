library hetimatorrent.dht.knode;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import 'package:hetimanet/hetimanet.dart';


class KNodeCommSimuMane {
  KNodeCommSimuMane._em();
  static KNodeCommSimuMane _mane = new KNodeCommSimuMane._em();
  static KNodeCommSimuMane get instance => _mane;

  Map<String, KNodeCommSimu> nodes = {};
}

class KNodeCommSimu extends HetiUdpSocket {
  String _ip = "";
  int _port;
  
  String get ip => _ip;
  int get port => _port;

  Future<int> bind(String ip, int port) {
    this._ip = ip;
    this._port = port;
    return new Future(() {
      if (KNodeCommSimuMane.instance.nodes.containsKey("${ip}:${port}")) {
        throw {"":"already start"};
      }
      KNodeCommSimuMane.instance.nodes["${ip}:${port}"] = this;
    });
  }

  Future<dynamic> close() {
    return new Future((){
      KNodeCommSimuMane.instance.nodes["${ip}:${port}"] = this;      
    });
  }

  Future<HetiUdpSendInfo> send(List<int> buffer, String ip, int port) {
    return new Future((){
      if (!KNodeCommSimuMane.instance.nodes.containsKey("${ip}:${port}")) {
        throw {"":"not found"};
      }
      return KNodeCommSimuMane.instance.nodes["${ip}:${port}"].receive(buffer, _ip, _port);
    });
  }
  
  StreamController _receiveMessage = new StreamController.broadcast();
  Stream<HetiReceiveUdpInfo> onReceive() {
    return _receiveMessage.stream;
  }

  Future receive(List<int> bytes, String ip, int port) {
    return new Future(() {
      _receiveMessage.add(new HetiReceiveUdpInfo(bytes, ip, port));      
    });
  }
}

class KNode {}
