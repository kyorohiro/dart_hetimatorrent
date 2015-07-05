library hetimatorrent.torrent.trackerurl;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../file/torrentfile.dart';

class TrackerUrl {
  static const String KEY_INFO_HASH = "info_hash";
  static const String KEY_PEER_ID = "peer_id";
  static const String KEY_PORT = "port";
  static const String KEY_EVENT = "event";
  static const String VALUE_EVENT_STARTED = "started";
  static const String VALUE_EVENT_STOPPED = "stopped";
  static const String VALUE_EVENT_COMPLETED = "completed";
  static const String KEY_DOWNLOADED = "downloaded";
  static const String KEY_UPLOADED = "uploaded";
  static const String KEY_LEFT = "left";
  static final String KEY_COMPACT = "compact";
  static const String KEY_OPT_IP = "ip";
  
  String trackerHost = "127.0.0.1";
  int trackerPort = 6969;
  String path = "/announce";
  String scheme = "http";
  int port = 6969;

  String infoHashValue = "";
  String peerID = "";
  String event = "";
  int downloaded = 0;
  int uploaded = 0;
  int left = 0;
  String ip = null;

  void set announce(String announce) {
    HttpUrlDecoder decoder = new HttpUrlDecoder();
    HttpUrl url = decoder.innerDecodeUrl(announce);
    trackerHost = url.host;
    trackerPort = url.port;
    scheme = url.scheme;
    path = url.path;
  }

  String toString() {
    return scheme + "://" + trackerHost + ":" + trackerPort.toString() + "" + path + toHeader();
  }

  String toHeader() {
    String ret =  
        "?${KEY_INFO_HASH}=${infoHashValue}"+
        "&${KEY_PORT}=${port.toString()}"+
        "&${KEY_PEER_ID}=${peerID}"+
        "&${KEY_EVENT}=${event}"+
        "&${KEY_UPLOADED}=${uploaded}"+
        "&${KEY_DOWNLOADED}=${downloaded}" +
        "&${KEY_LEFT}=${left.toString()}";
    if(ip != null) {
      ret += "${KEY_OPT_IP}:${ip}";
    }
    return ret;
  }

  TrackerUrl(String announce, List<int> infoHash, List<int> peerId, {String event:TrackerUrl.VALUE_EVENT_STARTED, int downloaded:0,int uploaded:0,int left:0,port:6969}) {
    this.announce = announce;
    this.peerID = PercentEncode.encode(peerId);
    this.infoHashValue = PercentEncode.encode(infoHash);
    this.event = TrackerUrl.VALUE_EVENT_STARTED;
    this.downloaded = downloaded;
    this.uploaded = uploaded;
    this.left = left;
    this.port = port;
  }

  static Future<TrackerUrl> createTrackerUrlFromTorrentFile(TorrentFile torrentfile, List<int> peerId) {
    return torrentfile.createInfoSha1().then((List<int> infoHash) {
      return new TrackerUrl(torrentfile.announce, infoHash, peerId);
    });
  }
}
