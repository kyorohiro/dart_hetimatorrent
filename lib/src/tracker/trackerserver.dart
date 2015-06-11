library hetimatorrent.torrent.trackerrserver;

import 'dart:core';
import 'dart:typed_data' as type;
import 'dart:async' as async;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'trackerurl.dart';
import 'trackerpeermanager.dart';
import '../torrent/bencode.dart';
import '../torrent/hetibencode.dart';
import 'trackerresponse.dart';
import 'trackerrequest.dart';

class TrackerServer {
  String address;
  int port;
  HetiHttpServerHelper _server = null;
  bool outputLog = true;
  List<TrackerPeerManager> _peerManagerList = new List();


  TrackerServer(HetiSocketBuilder socketBuilder) {
    _server = new HetiHttpServerHelper(socketBuilder);
    address = "0.0.0.0";
    port = 6969;
  }

  void add(String hash) {
    if (outputLog) {
      print("TrackerServer#add:" + hash);
    }

    type.Uint8List infoHashAs = PercentEncode.decode(hash);
    List<int> infoHash = infoHashAs.toList();
    bool isManaged = false;

    for (TrackerPeerManager m in _peerManagerList) {
      if (m.isManagedInfoHash(infoHash)) {
        isManaged = true;
      }
    }

    if (isManaged == true) {
      if (outputLog) {
        print("TrackerServer#add:###non:" + hash);
      }
      return;
    }

    TrackerPeerManager peerManager = new TrackerPeerManager(infoHash);
    _peerManagerList.add(peerManager);
    if (outputLog) {
      print("TrackerServer#add:###add:" + hash);
    }
  }

  async.Future<StartResult> start() {
    if (outputLog) {
      print("TrackerServer#start");
    }
    async.Completer<StartResult> c = new async.Completer();
    _server.basePort = port;
    _server.numOfRetry = 0;

    _server.startServer().then((HetiHttpStartServerResult re) {
      c.complete(new StartResult());
    }).catchError((e) {
      c.completeError(e);
    });
    _server.onResponse.listen(onListen);
    return c.future;
  }

  async.Future<StopResult> stop() {
    if (outputLog) {
      print("TrackerServer#stop");
    }
    async.Completer<StopResult> c = new async.Completer();
    _server.stopServer();
    c.complete(new StopResult());
    return c.future;
  }

  void onListen(HetiHttpServerPlusResponseItem item) {
    try {
      item.socket.getSocketInfo().then((HetiSocketInfo info) {
        try {
          if (outputLog) {
            print("TrackerServer#onListen ${info.peerAddress} ${info.peerPort}");
          }
          List<int> ip = HetiIP.toRawIP(info.peerAddress);       
          String qurey =item.option.replaceFirst(new RegExp(r"^\?"), "");
          updateResponse(qurey, ip);   
          List<int> cont = createResponse(item.option);
          _server.response(item.req, new HetimaDataMemory(cont));
        } catch (e) {
          print("error:" + e.toString());
        } finally {
        }
      });
    } catch (e) {
      try {
       item.socket.close();
      } catch (f) {}
    }
  }

  List<int> createResponse(String query) {
    if (outputLog) {
      print("TrackerServer#onListen" + query);
    }

    Map<String, String> parameter = HttpUrlDecoder.queryMap(query.replaceFirst(new RegExp(r"^\?"), ""));
    String infoHashAsString = parameter[TrackerUrl.KEY_INFO_HASH];
    String compactAsString = parameter[TrackerUrl.KEY_COMPACT];

    bool isCompact = false;
    if (compactAsString != null && compactAsString == "1") {
      isCompact = true;
    }

    List<int> infoHash = PercentEncode.decode(infoHashAsString);
    TrackerPeerManager manager = find(infoHash);

    if (null == manager) {
      if (outputLog) {
        print("TrackerServer#onListen:###unmanaged");
      }
      // unmanaged torrent data
      Map<String, Object> errorResponse = new Map();
      errorResponse[TrackerResponse.KEY_FAILURE_REASON] = "unmanaged torrent data";
      return Bencode.encode(errorResponse).toList();
    } else {
      // managed torrent data
      type.Uint8List buffer = Bencode.encode(manager.createResponse().createResponse(isCompact));
      if (outputLog) {
        print("TrackerServer#onListen:###managed" + PercentEncode.encode(buffer.toList()));
      }
      return buffer.toList();
    }
  }

  void updateResponse(String query, List<int> ip) {
    if (outputLog) {
      print("TrackerServer#updateResponse" + query);
    }
    Map<String, String> parameter = HttpUrlDecoder.queryMap(query);
    String infoHashAsString = parameter[TrackerUrl.KEY_INFO_HASH];

    List<int> infoHash = PercentEncode.decode(infoHashAsString);
    TrackerPeerManager manager = find(infoHash);

    if (null != manager) {
      // managed torrent data
      manager.update(new TrackerRequest.fromMap(parameter, address, ip));
    }
  }

  TrackerPeerManager find(List<int> infoHash) {
    for (TrackerPeerManager l in _peerManagerList) {
      if (l.isManagedInfoHash(infoHash)) {
        return l;
      }
    }
    return null;
  }
}

class StopResult {}
class StartResult {}
