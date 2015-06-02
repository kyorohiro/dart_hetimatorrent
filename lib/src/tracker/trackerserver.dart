part of hetima_sv;

class TrackerServer {
  String address;
  int port;
  io.HttpServer _server = null;
  bool outputLog = true;
  List<TrackerPeerManager> _peerManagerList = new List();

  TrackerServer() {
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
    io.HttpServer.bind(address, port).then((io.HttpServer server) {
      _server = server;
      server.listen(onListen);
      c.complete(new StartResult());
      if (outputLog) {
        print("TrackerServer#start:##ok");
      }
    }).catchError((e) {
      c.complete(new StartResult());
      if (outputLog) {
        print("TrackerServer#start:##ng");
      }
    });
    return c.future;
  }

  async.Future<StopResult> stop() {
    if (outputLog) {
      print("TrackerServer#stop");
    }
    async.Completer<StopResult> c = new async.Completer();
    _server.close(force: true).then((e) {
      if (outputLog) {
        print("TrackerServer#end");
      }
    });
    return c.future;
  }

  void onListen(io.HttpRequest request) {
    try {
      if (outputLog) {
        print("TrackerServer#onListen" + request.uri.toString());
      }
      io.InternetAddress addressAsInet = request.connectionInfo.remoteAddress;
      List<int> ip = addressAsInet.rawAddress;
      updateResponse(request.uri.query, ip);
      List<int> cont = createResponse(request.uri.query);
      request.response.statusCode = io.HttpStatus.OK;
      request.response.add(cont);
    } catch (e) {
      request.response.statusCode = io.HttpStatus.BAD_REQUEST;
      print("error:" + e.toString());
    } finally {
      try {
        request.response.close();
      } catch (f) {}
    }
  }

  List<int> createResponse(String query) {
    if (outputLog) {
      print("TrackerServer#onListen" + query);
    }
    Map<String, String> parameter = HttpUrlDecoder.queryMap(query);
    String infoHashAsString = parameter[TrackerUrl.KEY_INFO_HASH];
    String compactAsString = parameter[TrackerUrl.KEY_COMPACT];

    bool isCompact = false;
    if (compactAsString != null && compactAsString == "1") {
      isCompact = true;
    }

    List<int> infoHash = PercentEncode.decode(infoHashAsString);
    TrackerPeerManager manager = find(infoHash);

    if (null == manager) {
      if (outputLog) { print("TrackerServer#onListen:###unmanaged");}
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
    if (outputLog) {print("TrackerServer#updateResponse" + query);}
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


class StopResult {
}
class StartResult {
}
