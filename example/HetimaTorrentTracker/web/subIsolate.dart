library hetimatorrent.torrent.file.iso;
import "dart:isolate";
import 'package:crypto/crypto.dart' as crypto;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
//import '../util/bencode.dart';

void main(List<String> args, SendPort sendPort){
  ReceivePort fromMainIsolate = new ReceivePort();
  sendPort.send(fromMainIsolate.sendPort);
  fromMainIsolate.listen((message){
    sendPort.send("6");
    /*
    int id = message[0];
    List<int> parameters = message[1];
    crypto.SHA1 sha1 = new crypto.SHA1();    
    sha1.add(parameters);
      sendPort.send("${id}:${PercentEncode.encode(sha1.close())}");
      */
  });
}

