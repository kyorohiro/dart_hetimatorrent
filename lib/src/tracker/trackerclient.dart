library hetimatorrent.torrent.trackermanager;
import 'dart:core';
import 'dart:async' as async;
import 'trackerresponse.dart';
import 'trackerurl.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../file/torrentfile.dart';

class TrackerClient {

  TrackerUrl trackerUrl = new TrackerUrl();
  String get trackerHost => trackerUrl.trackerHost;
  void set trackerHost(String host) {
    trackerUrl.trackerHost = host;
  }

  int get trackerPort => trackerUrl.trackerPort;
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
  HetiSocketBuilder _socketBuilder = null;

  TrackerClient(HetiSocketBuilder builder) {
    _socketBuilder = builder;
  }

  void updateAnnounce(String announce) {
    this.trackerUrl.announce = announce;
  }

  async.Future updateFromMetaData(TorrentFile f) {
    async.Completer<Object> c = new async.Completer();
    updateAnnounce(f.announce);
    f.createInfoSha1().then((List<int> v){
      infoHash = PercentEncode.encode(v);
      c.complete({});
    });
    return c.future;
  }
 
  // todo support redirect 
  async.Future<TrackerRequestResult> requestWithSupportRedirect(int redirectMax) {
  }

  async.Future<TrackerRequestResult> request() {
    async.Completer<TrackerRequestResult> completer = new async.Completer();

    HetiHttpClient currentClient = new HetiHttpClient(_socketBuilder);
    HetiHttpClientResponse httpResponse = null;
    print("--[A0]-" + trackerHost + "," + trackerPort.toString() + "," + path + header);
    currentClient.connect(trackerHost, trackerPort).then((HetiHttpClientConnectResult state) {
      return currentClient.get(path+header, {"Connection" : "close"});
    }).then((HetiHttpClientResponse response){
      httpResponse = response;
      return TrackerResponse.createFromContent(response.body);
    }).then((TrackerResponse trackerResponse) {
      completer.complete(new TrackerRequestResult(trackerResponse, TrackerRequestResult.OK, httpResponse));
    }).catchError((e) {
      completer.complete(new TrackerRequestResult(null, TrackerRequestResult.ERROR, httpResponse));
      print("##er end");
    }).whenComplete(() {
      currentClient.close();
      print("###done end");
    });
    return completer.future;
  }
}

class TrackerRequestResult {
  int code = 0;
  static final int OK = 0;
  static final int ERROR = -1;
  TrackerResponse response = null;
  HetiHttpClientResponse httpResponse = null;
  TrackerRequestResult(TrackerResponse _respose, int _code, HetiHttpClientResponse _httpResponse) {
    code = _code;
    response = _respose;
    httpResponse = _httpResponse;
  }
}
