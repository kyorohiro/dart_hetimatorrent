import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_dartio.dart';
import 'package:hetimacore/hetimacore_dartio.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:args/args.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DHT {
  KNode node = new KNode(new HetimaSocketBuilderDartIO(verbose: false));
  List<KId> get infoHashs => node.targetInfoHashs;

  Future start(String ip, int port) {
    return node.start(ip: ip, port: port).then((_) {
      node.onGetPeerValue.listen((KGetPeerValue v) {
        print("---onGetPeerValue ${v.ipAsString} ${v.port} ${v.infoHashAsString} ");
      });
    });
  }

  Future stop() {
    return node.stop();
  }

  addNode(String ip, int port) {
    node.addBootNode(ip, port);
  }

  Future addTarget(List<int> infoHash) {
    return node.startSearchValue(new KId(infoHash), 18080, getPeerOnly: true);
  }

  Future rmTarget(List<int> infoHash) {
    return node.stopSearchValue(new KId(infoHash));
  }

  String log() {
    return node.rootingtable.toInfo().replaceAll("\n", "<br>");
  }
  
  String rootingTable() {
    return node.rootingtable.toInfo();
  }
}

main(List<String> args) async {
  DHT dht = await aaa(args);
  a(dht, "addbootnode", 
//      ["157.7.205.138", "51413"]);
    ["love.hetimatan.net", "51413"]);
  a(dht, "start", ["0.0.0.0", "38080"]);

  await new Future.delayed(new Duration(seconds:60));
  a(dht, "rootingtable", []);
  a(dht, "stop", []);
//  ["love.hetimatan.net", "51413"]);
}

bool logOnReceiveMessage = false;

Future<DHT> aaa(List<String> args) async {
  String exec = Platform.executable;
  List<String> flags = Platform.executableArguments;
  print("hello ${exec} ${flags} ${args}");

  ArgParser parser = new ArgParser()
    ..addFlag("a", negatable: true, abbr: 'a')
    ..addFlag("b", negatable: false, abbr: 'b')
    ..addOption("c", abbr: 'c');
  ArgResults result = parser.parse(args);
  print("${result.rest} ${result['a']} ${result['b']} ${result['c']}");

  bool nowActing = false;
  DHT dht = new DHT();
  stdin.asBroadcastStream().listen((List<int> v) {
    if (nowActing == true) {
      return;
    }
    nowActing = true;
    b(dht, v).then((_) {
      nowActing = false;
      print("---ok!!");
    }).catchError((_) {
      nowActing = false;
      print("---error!!");
    });
  });
  return dht;
}

Future b(DHT dht, List<int> v) async {
  String line = UTF8.decode(v);
  List<String> lineparts = line.split(new RegExp("[ ]+|\t|\r\n|\r|\n"));
  if (lineparts.length == 0) {
    return null;
  }

  String action = lineparts[0];
  List<String> args = [];
  if (lineparts.length > 1) {
    args.addAll(lineparts.sublist(1));
  }
  return a(dht, action, args);
}

Future a(DHT dht, String action, List<String> args) async {
  print(">> action:${action} args:${args}");
  switch (action.toLowerCase()) {
    case "help":
      print("""
        exit : exit this application.
        start <ip:striing> <port:number> :
        stop :
        addBootNode <ip:string> <port:number>
        addTraget <xx.torrent path:string>:
        rmTarget <id:number>
        infoHashs : display infohash and id
        rootingtable : display rootingtable
      """);
      break;
    case "exit":
      print("..\ngoodbye!!\n..\n");
      exit(0);
      break;
    case "start":
      await dht.start(args[0], int.parse(args[1]));
      break;
    case "stop":
      await dht.stop();
      break;
    case "addbootnode":
      await dht.addNode(args[0], int.parse(args[1]));
      break;
    case "addtarget":
      TorrentFile torrentfile = await TorrentFile.createFromTorrentFile(new HetimaDataToReader(new HetimaDataDartIO(args[0])));
      print("f = ${torrentfile}");
      print("f.announce = ${torrentfile.announce}");
      List<int> infohash = await torrentfile.createInfoSha1();
      await  dht.addTarget(infohash);
      break;
    case "infohashs":
      int id = 0;
      print("[ index ]  :  infohash");
      for(List<int> infohash in dht.infoHashs) {
        print("[ ${id} ]  :  ${CryptoUtils.bytesToBase64(infohash)}");
      }
      break;
    case "rmtarget":
      await dht.rmTarget(dht.infoHashs[int.parse(args[0])].value);
      break;
    case "rootingtable":
      print("${dht.rootingTable()}");
      break;
    case "networkinterface":
      UpnpPortMapHelper h = new UpnpPortMapHelper(new HetimaSocketBuilderDartIO(), "test");
      StartGetLocalIPResult r = await h.startGetLocalIp();
      for(HetimaNetworkInterface i in r.networkInterface) {
        print("${i.address} ${i.name} ${i.prefixLength}");
      }
      break;
    case "messageon":
      print("meesageon");
      logOnReceiveMessage = true;
      break;
    case "messageoff":
      logOnReceiveMessage = false;
      break;
    default:
      throw "commmand not found";
  }
}


onReceiveMessage(TorrentClientMessage message) {
  if(logOnReceiveMessage == true) {
    print("message = ${message}");
  }
}