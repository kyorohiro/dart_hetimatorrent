library hetimatorrent.torrent.trackerresponse;

import 'dart:core';
import 'dart:typed_data' as data;
import 'dart:async' as async;
import 'dart:convert' as convert;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'trackerpeerinfo.dart';
import '../util/bencode.dart';
import '../util/hetibencode.dart';

class TrackerResponse {
  static final String KEY_INTERVAL = "interval";
  static final String KEY_PEERS = "peers";
  static final String KEY_PEER_ID = "peer_id";
  static final String KEY_IP = "ip";
  static final String KEY_PORT = "port";
  static final String KEY_FAILURE_REASON = "failure reason";

  int interval = 10;
  List<TrackerPeerInfo> peers = [];
  TrackerResponse() {}

  TrackerResponse.bencode(data.Uint8List contents) {
    Map<String, Object> c = Bencode.decode(contents);
    initFromMap(c);
  }

  static async.Future<TrackerResponse> createFromContent(HetimaReader builder) {
    async.Completer<TrackerResponse> completer = new async.Completer();
    EasyParser parser = new EasyParser(builder);
    HetiBencode.decode(parser).then((Object o) {
      Map<String, Object> c = o;
      TrackerResponse instance = new TrackerResponse();
      instance.initFromMap(c);
      completer.complete(instance);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  initFromMap(Map<String, Object> c) {
    interval = c[KEY_INTERVAL];
    Object obj = c[KEY_PEERS];

    if (obj is data.Uint8List) {
      data.Uint8List wpeers = c[KEY_PEERS];
      for (int i = 0; i < wpeers.length; i += 6) {
        List<int> wpeer = [wpeers[i + 0], wpeers[i + 1], wpeers[i + 2], wpeers[i + 3]];
        List<int> port = [wpeers[i + 4], wpeer[i + 5]];
        peers.add(new TrackerPeerInfo([], "", wpeer.toList(), ByteOrder.parseInt(port, 0, 2)));
      }
    } else {
      List<Object> wpeers = c[KEY_PEERS];
      for (Map<String, Object> wpeer in wpeers) {
        String ip = "";
        if (wpeer[KEY_IP] is String) {
          ip = wpeer[KEY_IP];
        } else {
          ip = convert.UTF8.decode(wpeer[KEY_IP]);
        }
        data.Uint8List peeerid = wpeer[KEY_PEER_ID];
        int port = wpeer[KEY_PORT];
        peers.add(new TrackerPeerInfo(peeerid.toList(), "", HetiIP.toRawIP(ip), port));
      }
    }
  }

  Map<String, Object> createResponse(bool isCompat, [bool toGlobalDevice = true]) {
    Map ret = new Map();
    ret[KEY_INTERVAL] = interval;
    if (isCompat) {
      ArrayBuilder builder = new ArrayBuilder();
      for (TrackerPeerInfo p in peers) {
        if (toGlobalDevice) {
          //
          // return global ip only, when target device is from global ip.
          // for global network device
          if (true == HetiIP.isLocalNetwork(p.ip)) {
            if (false == HetiIP.isLocalNetwork(p.optIp) && HetiIP.isIpV4(p.optIp)) {
              builder.appendIntList(p.optIp, 0, p.optIp.length);
              builder.appendIntList(ByteOrder.parseShortByte(p.port, ByteOrder.BYTEORDER_BIG_ENDIAN), 0, 2);
            }
          } else if (HetiIP.isIpV4(p.ip)) {
            builder.appendIntList(p.ip, 0, p.ip.length);
            builder.appendIntList(ByteOrder.parseShortByte(p.port, ByteOrder.BYTEORDER_BIG_ENDIAN), 0, 2);
          }
        } else {
          //
          // for localnetwork device
          if (true == HetiIP.isIpV4(p.ip)) {
            builder.appendIntList(p.ip, 0, p.ip.length);
            builder.appendIntList(ByteOrder.parseShortByte(p.port, ByteOrder.BYTEORDER_BIG_ENDIAN), 0, 2);
          }
        }
      }
      ret[KEY_PEERS] = builder.toUint8List();
    } else {
      List wpeers = ret[KEY_PEERS] = [];
      for (TrackerPeerInfo p in peers) {
        Map wpeer = {};
        wpeer[KEY_IP] = p.ipAsString;
        wpeer[KEY_PEER_ID] = new data.Uint8List.fromList(p.peerId);
        wpeer[KEY_PORT] = p.port;
        wpeers.add(wpeer);
      }
    }
    return ret;
  }

}
