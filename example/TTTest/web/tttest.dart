/*import "dart:isolate";

void main() {
  ReceivePort fromSubIsolate = new ReceivePort();
  Isolate.spawnUri(
      new Uri.file("subIsolate.dart"), 
      [],
      fromSubIsolate.sendPort);

  SendPort sendPort = null;
  
  fromSubIsolate.listen((message){
    if(message is SendPort){
      sendPort = message;
      sendPort.send([1, 2]);
    }
    if(message is int){
      print(message);
    }
  });
}
*/
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'dart:async';

void main() {
  SHA1Iso iso = new SHA1Iso(2);
  iso.init(path:"subIsolate.dart").then((_){
    a(List<int> data, int id, String mes) {
      iso.requestSingleWait([1,2,3], id).then((RequestSingleWaitReturn req) {
        return req.v.then((List<List<int>> v) {
        print("${mes} ${v}");
        });
      });
    }
    
   List<int> data = new List.filled(256*1024, 1);
    new Future(() {
      a(data, 0, "[A]");
      a(data, 1, "[B]");     
      a(data, 0, "[C]");
       a(data, 1, "[D]");
     });
  });
}