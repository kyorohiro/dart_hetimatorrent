library hetimatorrent.torrent.file.iso;
import "dart:isolate";
import 'package:crypto/crypto.dart' as crypto;
import '../util/bencode.dart';

void main(List<String> args, SendPort sendPort){
  ReceivePort fromMainIsolate = new ReceivePort();
  sendPort.send(fromMainIsolate.sendPort);
  fromMainIsolate.listen((message){
    int id = message[0];
    List<int> parameters = message[1];
    crypto.SHA1 sha1 = new crypto.SHA1();
    message[1] = sha1.add(message[1]);
    sendPort.send(message);
  });
}

