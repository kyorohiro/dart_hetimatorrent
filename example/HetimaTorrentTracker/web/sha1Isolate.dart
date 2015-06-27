library hetimatorrent.torrent.file.iso;

import "dart:isolate";
import 'package:crypto/crypto.dart' as crypto;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';
import 'dart:async';

void main(List<String> args, SendPort sendPort) {
  ReceivePort fromMainIsolate = new ReceivePort();
  sendPort.send(fromMainIsolate.sendPort);
  fromMainIsolate.listen((message) {
    int id = message[0];
    List<int> parameters = message[1];
    crypto.SHA1 sha1 = new crypto.SHA1();
    sha1.add(parameters);
    sendPort.send(sha1.close());
  });
}

class SHA1Iso {
  List<ReceivePort> receivePort = [];

  SHA1Iso(int num) {
    if (num < 1) {
      throw {};
    }

    for (int i = 0; i < num; i++) {
      receivePort.add(new ReceivePort());
    }
  }

  Future init() {
    Completer c = new Completer();
    int count = 0;
    for (ReceivePort port in receivePort) {
      StreamSubscription cancel = null;
      cancel = port.listen((message) {
        if (message is SendPort) {
          count++;
          cancel.cancel();
          if (count >= receivePort.length && !c.isCompleted) {
            c.complete();
          }
        }
        if (message is String) {
          print(message);
        }
      });
      Isolate.spawnUri(new Uri.file("sha1Isolate.dart"), [], port.sendPort);
    }
    return c.future;
  }

  Future<List<List<int>>> request(List<List<int>> bytes) {
    Completer c = new Completer();
    int count = 0;
    int length = receivePort.length;
    List<List<int>> ret = [];
    if(bytes.length < length) {
      length = bytes.length;
    }
    for (int i = 0; i < receivePort.length; i++) {
      receivePort[i].listen((message) {
        if (message is List) {
          ret.add(message);
          if (length == count) {
            c.complete(ret);
          }
        }
      });
      receivePort[i].sendPort.send(bytes[i]);
    }
    return c.future;
  }
}
