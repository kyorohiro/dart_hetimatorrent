library hetimatorrent.torrent.file.iso;

import "dart:isolate";
import 'package:crypto/crypto.dart' as crypto;
import 'dart:async';

class SHA1IsoSub {
  void main(List<String> args, SendPort sendPort) {
    print("created SHA1IsoSub");
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
}

class SHA1IsoInfo {
  ReceivePort receivePort= null;
  StreamSubscription streanSubscription = null;
}

class SHA1Iso {
  List<SHA1IsoInfo> receivePort = [];

  SHA1Iso(int num) {
    if (num < 1) {
      throw {};
    }

    for (int i = 0; i < num; i++) {
      receivePort.add(new SHA1IsoInfo()..receivePort=new ReceivePort());
    }
  }

  Future init({String path:"sha1Isolate.dart"}) {
    Completer c = new Completer();
    int count = 0;
    for (SHA1IsoInfo info in receivePort) {
      StreamSubscription cancel = null;
      ReceivePort port = info.receivePort;
      info.streanSubscription = cancel = port.listen((message) {
        if (message is SendPort) {
          count++;
          //cancel.cancel();
          if (count >= receivePort.length && !c.isCompleted) {
            c.complete();
          }
        }
        if (message is String) {
          print(message);
        }
      });
      Isolate.spawnUri(new Uri.file(path), [], port.sendPort);
    }
    return c.future;
  }

  Future<List<List<int>>> request(List<List<int>> bytes) {
    Completer c = new Completer();
    int count = 0;
    int length = receivePort.length;
    List<List<int>> ret = [];
    if (bytes.length < length) {
      length = bytes.length;
    }
    for (int i = 0; i < length; i++) {
      receivePort[i].streanSubscription.onData((message) {
        if (message is List) {
          ret.add(message);
          count++;
          if (length == count) {
            c.complete(ret);
          }
        }
      });
      receivePort[i].receivePort.sendPort.send(bytes[i]);
    }
    return c.future;
  }
}
