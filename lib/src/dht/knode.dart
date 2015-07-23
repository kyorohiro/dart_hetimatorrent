library hetimatorrent.dht.knode;

import 'dart:core';
import 'dart:async';
import 'dart:math';
import 'package:hetimanet/hetimanet.dart';

class KNode {
  HetiSocketBuilder _socketBuilder = null;
  HetiUdpSocket _udpSocket = null;

  KNode(HetiSocketBuilder socketBuilder) {
    this._socketBuilder = socketBuilder;
  }

  Future start({String ip: "0.0.0.0", int port: 28080}) {
    return new Future(() {
      if (_udpSocket != null) {
        throw {};
      }
      _udpSocket = this._socketBuilder.createUdpClient();
      return _udpSocket.bind(ip, port);
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
