library hetimatorrent.torrent.g;

import "dart:isolate";
import 'package:hetimatorrent/hetimatorrent.dart';

void main(List<String> args, SendPort sendPort) {
  print("------subiso init");
  SHA1IsoSub sub = new SHA1IsoSub();
  sub.main(args, sendPort);
}

/*
import "dart:isolate";

void main(List<String> args, SendPort sendPort){
  ReceivePort fromMainIsolate = new ReceivePort();
  sendPort.send(fromMainIsolate.sendPort);
  fromMainIsolate.listen((message){
    List<int> parameters = message;
    sendPort.send(parameters.reduce((a, b) => a + b));
  });
}

import "dart:isolate";

void main(List<String> args, SendPort sendPort){
  ReceivePort fromMainIsolate = new ReceivePort();
  sendPort.send(fromMainIsolate.sendPort);
  fromMainIsolate.listen((message){
    List<int> parameters = message;
    sendPort.send(parameters.reduce((a, b) => a + b));
  });
}
*/
