library hetimatorrent.torrent.trackerpeerinfo;

import 'dart:core';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';

class TrackerPeerInfo {
  List<int> peerId;
  String address;
  List<int> ip;
  int port;
  int _time = 0;
  String optIpAsString = "";
  List<int> get optIp {
    if(optIpAsString == null || optIpAsString.length == 0)  {
      return new List.from(ip);
    } else {
      return HetiIP.toRawIP(optIpAsString);
    }
  }

  int get time => _time;
  TrackerPeerInfo(List<int> _peerId, String _address, List<int> _ip, int _port, [String optIp=""]) {
    peerId = new List.from(_peerId);
    address = _address;
    ip = new List.from(_ip);
    port = _port;
    this.optIpAsString = optIp; 
    update();
  }

  void update() {
    _time = (new DateTime.now()).millisecondsSinceEpoch;
  }

  bool operator == (other) {
    if (other is TrackerPeerInfo) {
      if (other.peerId.length != peerId.length) {
        return false;
      }
      for (int i = 0; i < peerId.length; i++) {
        if (other.peerId[i] != peerId[i]) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  String get peerIdAsString => PercentEncode.encode(peerId);
  String get portdAsString => port.toString();
  String get ipAsString {
    return "" + ip[0].toString() + "." + ip[1].toString() + "." + ip[2].toString() + "." + ip[3].toString();
  }
}


