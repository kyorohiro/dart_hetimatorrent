library hetimatorrent.dht.knode;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'krootingtable.dart';

class KNode {
  HetiSocketBuilder _socketBuilder = null;
  HetiUdpSocket _udpSocket = null;
  KRootingTable _rootingtable = null;
  Map<String,EasyParser> buffers = {};

  KNode(HetiSocketBuilder socketBuilder,[int k_bucketSize=8]) {
    this._socketBuilder = socketBuilder;
    this._rootingtable = new KRootingTable(k_bucketSize);
  }

  Future start({String ip: "0.0.0.0", int port: 28080}) {
    return new Future(() {
      if (_udpSocket != null) {
        throw {};
      }
      _udpSocket = this._socketBuilder.createUdpClient();
      return _udpSocket.bind(ip, port).then((int v){
        _udpSocket.onReceive().listen((HetiReceiveUdpInfo info){
          if(!buffers.containsKey("${info.remoteAddress}:${info.remotePort}")) {
            buffers["${info.remoteAddress}:${info.remotePort}"] = new EasyParser(new ArrayBuilder());
          }
          EasyParser parser = buffers["${info.remoteAddress}:${info.remotePort}"];
        });
      });
    });
  }

  Future stop() {
    return new Future(() {
      if (_udpSocket == null) {
        return null;
      }
      return _udpSocket.close();
    });
  }
}
