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

class KNodeCommSimulator {

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

class KNode {
  
}
