library hetimatorrent.torrent.trackerurl;
import 'dart:core';
import 'package:hetimanet/hetimanet.dart';

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
    return "?" + KEY_INFO_HASH + "=" + infoHashValue + "&" + KEY_PORT + "=" + port.toString() + "&" + KEY_PEER_ID + "=" + peerID + "&" + KEY_EVENT + "=" + event + "&" + KEY_UPLOADED + "=" + uploaded.toString() + "&" + KEY_DOWNLOADED + "=" + downloaded.toString() + "&" + KEY_LEFT + "=" + left.toString();
  }

}

