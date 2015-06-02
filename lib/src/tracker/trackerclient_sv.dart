part of hetima_sv;

class TrackerClientSv {
  TrackerUrl trackerUrl = new TrackerUrl();
  String get trackerHost => trackerUrl.trackerHost;
  void set trackerHost(String host) {
    trackerUrl.trackerHost = host;
  }
  int get trackerPort => 6969;
  void set trackerPort(int port) {
    trackerUrl.trackerPort = port;
  }
  int get peerport => trackerUrl.port;
  void set peerport(int port) {
    trackerUrl.trackerPort = port;
  }
  String get path => trackerUrl.path;
  void set path(String path) {
    trackerUrl.path = path;
  }
  String get event => trackerUrl.event;
  void set event(String event) {
    trackerUrl.event = event;
  }
  String get peerID => trackerUrl.peerID;
  void set peerID(String peerID) {
    trackerUrl.peerID = peerID;
  }
  String get infoHash => trackerUrl.infoHashValue;
  void set infoHash(String infoHash) {
    trackerUrl.infoHashValue = infoHash;
  }
  String get header => trackerUrl.toHeader();

  async.Future<RequestResultSv> request() {
    async.Completer<RequestResultSv> completer = new async.Completer();
    io.HttpClient client = new io.HttpClient();
    (new async.Future.sync(() {
      print("--[A0]-" + trackerHost + "," + trackerPort.toString() + "," + path + header);
      return client.get(trackerHost, trackerPort, path + header).then((io.HttpClientRequest request) {
        print("--[A1]-");
        return request.close().then((io.HttpClientResponse response) /**/
        {
          responseHandle(response, completer);
        }/**/
        );
      });
    })).catchError((e) {
      completer.complete(new RequestResultSv(null, RequestResultSv.ERROR));
      print("##er end");
    }).then((e) {
      print("###done end");
    });
    return completer.future;
  }

  void responseHandle(io.HttpClientResponse response, async.Completer<RequestResultSv> completer) /**/
  {
    print("--[A2]-");
    int redirectNum = 0;
    if(null != response.redirects && response.redirects.length>0) {
      response.redirect().then((io.HttpClientResponse response) {
        redirectNum++;
        if(redirectNum>5) {
          completer.complete(new RequestResultSv(null, RequestResultSv.ERROR));
        }
        responseHandle(response, completer);
      });
      return;
    }
    ArrayBuilder buffer = new ArrayBuilder();
    response.listen((List<int> contents) {
      print("--[A3]-" + contents.runtimeType.toString());
      print("listen:" + contents.length.toString());
//     print("ret:" + convert.UTF8.decode(contents.toList()));
      buffer.appendUint8List(contents, 0, contents.length);
    }).onDone(() {
      print("--[A4]-");
      print("done");
      TrackerResponse response = new TrackerResponse.bencode(buffer.toUint8List());
      //TrackerResponse response = new TrackerResponse();
      completer.complete(new RequestResultSv(response, RequestResultSv.OK));
    });
  }
}

class RequestResultSv {
  int code = 0;
  static final int OK = 0;
  static final int ERROR = -1;
  TrackerResponse response = null;
  RequestResultSv(TrackerResponse _respose, int _code) {
    code = _code;
    response = _respose;
  }
}
