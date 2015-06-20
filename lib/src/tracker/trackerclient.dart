library hetimatorrent.torrent.trackerclient;

import 'dart:core';
import 'dart:async' as async;
import 'trackerresponse.dart';
import 'trackerurl.dart';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../file/torrentfile.dart';
import '../util/peeridcreator.dart';

class TrackerClient {
  TrackerUrl trackerUrl;
  TrackerClient._a(HetiSocketBuilder builder, TrackerUrl trackerUrl) {
    this.trackerUrl = trackerUrl;
  }

  static async.Future<TrackerClient> createTrackerClient(HetiSocketBuilder builder, TorrentFile torrentfile, {List<int> peerId: null,int peerPort:16969}) {
    if(peerId == null) {
      peerId = PeerIdCreator.createPeerid("hetitor");
    }
    return TrackerUrl.createTrackerUrlFromTorrentFile(torrentfile, peerId).then((TrackerUrl url) {
      TrackerClient ret = new TrackerClient._a(builder, url);
      url.port = peerPort;
      return ret;
    });
  }

  String get trackerHost => trackerUrl.trackerHost;
  int get trackerPort => trackerUrl.trackerPort;
  int get peerport => trackerUrl.port;
  void set peerport(int port) {
    trackerUrl.port = port;
  }

  String get path => trackerUrl.path;
  String get event => trackerUrl.event;
  void set event(String event) {
    trackerUrl.event = event;
  }


  String get infoHash => trackerUrl.infoHashValue;
  String get header => trackerUrl.toHeader();
  HetiSocketBuilder _socketBuilder = null;


  // todo support redirect
  async.Future<TrackerRequestResult> requestWithSupportRedirect(int redirectMax) {
    
  }

  async.Future<TrackerRequestResult> request() {
    async.Completer<TrackerRequestResult> completer = new async.Completer();

    HetiHttpClient currentClient = new HetiHttpClient(_socketBuilder);
    HetiHttpClientResponse httpResponse = null;

    print("--[A0]-" + trackerHost + "," + trackerPort.toString() + "," + path + header);

    currentClient.connect(trackerHost, trackerPort).then((HetiHttpClientConnectResult state) {
      return currentClient.get(path + header, {"Connection": "close"});
    }).then((HetiHttpClientResponse response) {
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
