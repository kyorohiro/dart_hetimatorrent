library hetimatorrent.dht.knode;

import 'dart:core';
import 'dart:async';
import 'dart:math';

class KNodeComm {
  Future start(String ip, int port);
  Future stop();
  Future write(List<int> bytes);
  Future read(List<int> bytes);
}

class KNodeCommSimuMane {
  KNodeCommSimuMane._em();
  static KNodeCommSimuMane _mane = new KNodeCommSimuMane._em();
  static KNodeCommSimuMane get instance => _mane;
  
  Map<String, KNodeCommSimu> nodes = {};
}
class KNodeCommSimu {
  Future start(String ip, int port) {
    ;
  }
  Future stop() {
    ;
  }
  Future write(List<int> bytes) {
    ;
  }
  Future read(List<int> bytes) {
    ;
  }
}

class KNode {}
