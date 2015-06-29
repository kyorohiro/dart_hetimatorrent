library hetimatorrent.torrent.file.iso;

import "dart:isolate";
import 'package:crypto/crypto.dart' as crypto;
import 'dart:async';

class SHA1IsoSub {
  void main(List<String> args, SendPort sendPort) {
    //print("created SHA1IsoSub");
    ReceivePort fromMainIsolate = new ReceivePort();
    sendPort.send(fromMainIsolate.sendPort);

    fromMainIsolate.listen((message) {
      //print("message SHA1IsoSub");
      List<int> parameters = message;
      crypto.SHA1 sha1 = new crypto.SHA1();
      sha1.add(parameters);
      sendPort.send(sha1.close());
    });
  }
}

class SHA1IsoInfo {
  ReceivePort receivePort = null;
  StreamSubscription streanSubscription = null;
  SendPort sendPort = null;
  Completer c = null;
  Completer accessTicket = null;
}

class SHA1Iso {
  List<SHA1IsoInfo> receivePort = [];

  SHA1Iso(int num) {
    if (num < 1) {
      throw {};
    }

    for (int i = 0; i < num; i++) {
      receivePort.add(new SHA1IsoInfo()..receivePort = new ReceivePort());
    }
  }

  Future init({String path: "sha1Isolate.dart"}) {
    Completer c = new Completer();
    int count = 0;
    for (int ii =0;ii< receivePort.length;ii++) {
      int id = ii;
      SHA1IsoInfo info = receivePort[id];
      ReceivePort port = info.receivePort;
      info.streanSubscription = port.listen((message) {
        //print("### receice ${id}");

        if (message is SendPort) {
          count++;
          info.sendPort = message;
          //cancel.cancel();
          if (count >= receivePort.length && !c.isCompleted) {
            c.complete();
          }
        }
        else if (message is List && message.length == 20) {
          List<List<int>> ret = [];
          ret.add(message);
       //   print("receice ${id} ${receivePort[id].c.isCompleted} ${receivePort[id].accessTicket.isCompleted} ${ret}");
          //if(receivePort[id].c.isCompleted == false) {
            receivePort[id].c.complete(ret);
          //}
          //if(receivePort[id].accessTicket == false) {
            receivePort[id].accessTicket.complete({});
          //}
        }
        else {
         print("a${message}");
        }
      });
      Isolate.spawnUri(new Uri.file(path), [], port.sendPort);
    }
    return c.future;
  }

  Future<RequestSingleWaitReturn> requestSingleWait(List<int> bytes, int id) {
    if(receivePort[id].c == null || receivePort[id].c.isCompleted) {
     // print("--send ${id}");
      RequestSingleWaitReturn v = new RequestSingleWaitReturn();
      v.v = requestSingle(bytes, id);
      return new Future((){return v;});
    } else {
     // print("+*send ${id}");
      return receivePort[id].accessTicket.future.then((_){
     // print("++send ${id}");
        RequestSingleWaitReturn v = new RequestSingleWaitReturn();
        v.v = requestSingle(bytes, id);
        return v;
      });
    }
  }

  Future<List<List<int>>> requestSingle(List<int> bytes, int id) {
    receivePort[id].c = new Completer();
    receivePort[id].accessTicket = new Completer();
   // print("send[A] ${id}");
    receivePort[id].sendPort.send(bytes);
   // print("send[B] ${id}");
    return receivePort[id].c.future;
  }
}

class RequestSingleWaitReturn{
  Future<List<List<int>>>  v = null;
}