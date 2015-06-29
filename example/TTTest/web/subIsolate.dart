library def.g;

import "dart:isolate";
import 'package:crypto/crypto.dart' as crypto;
//import 'package:hetimatorrent/hetimatorrent.dart';

void main(List<String> args, SendPort sendPort) {
  //print("created SHA1IsoSub");
  ReceivePort fromMainIsolate = new ReceivePort();
  sendPort.send(fromMainIsolate.sendPort);

  fromMainIsolate.listen((message) {
    print("message SHA1IsoSub");
    List<int> parameters = message;
    crypto.SHA1 sha1 = new crypto.SHA1();
    sha1.add(parameters);
    sendPort.send(sha1.close());
  });
}
/*
void main(List<String> args, SendPort sendPort) {
  print("------subiso init");
  SHA1IsoSub sub = new SHA1IsoSub();
  sub.main(args, sendPort);
}
*/
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
