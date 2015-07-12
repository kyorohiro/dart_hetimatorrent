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
  static const String EVENT_STARTED = TrackerUrl.VALUE_EVENT_STARTED;
  static const String EVENT_COMPLETED = TrackerUrl.VALUE_EVENT_COMPLETED;
  static const String EVENT_STOPPED = TrackerUrl.VALUE_EVENT_STOPPED;

  TrackerUrl trackerUrl;
  HetiSocketBuilder _socketBuilder = null;
  TrackerClient._a(HetiSocketBuilder builder, TrackerUrl trackerUrl) {
    this.trackerUrl = trackerUrl;
    _socketBuilder = builder;
  }

  static async.Future<TrackerClient> createTrackerClient(HetiSocketBuilder builder, TorrentFile torrentfile, {List<int> peerId: null, int peerPort: 16969}) {
    if (peerId == null) {
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

  void set optIp(String ip) {
    trackerUrl.ip = ip;
  }

  String get optIp => trackerUrl.ip;

  String get infoHashAsPercentEncoding => trackerUrl.infoHashValue;
  String get header => trackerUrl.toHeader();
  String get peerIdAsPercentEncoding => trackerUrl.peerID;
  List<int> get peerId => PercentEncode.decode(trackerUrl.peerID);
  List<int> get infoHash => PercentEncode.decode(trackerUrl.infoHashValue);

  // todo support redirect
  async.Future<TrackerRequestResult> requestWithSupportRedirect(
      [int redirectMax=5, String host = null, int port = null,String path=null, String header=null]) {
    List<int> REDIRECT_STATUSCODE = [301, 302, 303, 307];
    if (host == null) {
      host = trackerHost;
    }
    if ( port== null) {
      port = trackerPort;
    }
    if(path == null) {
      path = this.path;
    }
    if(header == null) {
      header = this.header;
    }
    return request(host, port).then((TrackerRequestResult r) {
      HetiHttpResponseHeaderField locationField = r.httpResponse.message.find("Location");
      if (r.code == TrackerRequestResult.OK || redirectMax <= 0) {
        return r;
      } else if (REDIRECT_STATUSCODE.contains(r.httpResponse.message.line.statusCode) && locationField != null) {
        HttpUrl hurl = HttpUrlDecoder.decodeUrl(locationField.fieldValue, "http://${host}:${port}");
        if(hurl.query == null || hurl.query.length <= 3) {
          return requestWithSupportRedirect(redirectMax-1, hurl.host, hurl.port,hurl.path, this.header);          
        } else {
          return requestWithSupportRedirect(redirectMax-1, hurl.host, hurl.port,hurl.path,"?${hurl.query}");
        }
      } else {
        return r;
      }
    });
  }

  async.Future<TrackerRequestResult> request([String host=null, int port=null, String path=null, String header=null]) {
    async.Completer<TrackerRequestResult> completer = new async.Completer();

    HetiHttpClient currentClient = new HetiHttpClient(_socketBuilder);
    HetiHttpClientResponse httpResponse = null;
    if (host == null) {
      host = trackerHost;
    }
    if (port== null) {
      port = trackerPort;
    }
    
    if(path == null) {
      path = this.path;
    }
    if(header == null) {
      header = this.header;
    }

    print("--[A0]-" + host + "," + port.toString() + "," + path + header);

    currentClient.connect(host, port).then((HetiHttpClientConnectResult state) {
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
