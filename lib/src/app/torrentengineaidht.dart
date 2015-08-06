library hetimatorrent.extra.torrentengine.ai.dht;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentai.dart';
import '../client/torrentai_basic.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import '../dht/knode.dart';
import 'torrentengineaidht.dart';
import '../dht/message/kgetpeervalue.dart';

class TorrentEngineDHT extends TorrentAI {
  KNode _node = null;

  UpnpPortMapHelper _upnpPortMapClient = null;
  HetiSocketBuilder _socketBuilder = null;
  String _localIp = "0.0.0.0";
  int _localPort = 0;

  bool _useUpnp = false;
  bool get useUpnp => _useUpnp;

  int _intervalSecondForAnnounce = 60;
  TorrentEngineDHT(HetiSocketBuilder socketBuilder, String appid, 
      {String localIp: "0.0.0.0", int localPort: 38080, bool useUpnp: false, int intervalSecondForAnnounce: 120}) {
    _upnpPortMapClient = new UpnpPortMapHelper(socketBuilder, appid);
    _localIp = localIp;
    _localPort = localPort;
    _socketBuilder = socketBuilder;
    _useUpnp = useUpnp;
    _intervalSecondForAnnounce = intervalSecondForAnnounce;
  }

  Future start() {
    return new Future(() {
      int count = 0;
      _node = new KNode(_socketBuilder, intervalSecondForAnnounce: _intervalSecondForAnnounce);

      a() {
        if (useUpnp) {
          return _startPortMap().then((_) {
            return {};
          }).catchError((e) {
            _localPort++;
            count++;
            return _node.stop().then((_){
              if (count < 5) {
                return a();
              }              
            });
          });
        } else {
          return {};
        }
      }
      b() {
        return _node.start(ip: _localIp, port: _localPort).then((_) {
          return a();
        }).catchError((e) {
          _localPort++;
          count++;
          if (count < 5) {
            return b();
          }
        });
      }
      return b();
    });
  }

  Future stop() {
    return new Future(() {
      _node.stop();
      _upnpPortMapClient.deletePortMapFromAppIdDesc(reuseRouter: true, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_UDP);
    });
  }

  Future startSearchPeer(KId infoHash, int port) {
    return _node.startSearchValue(infoHash, port);
  }

  Future stopSearchPeer(KId infoHash) {
    return _node.stopSearchPeer(infoHash);
  }

  @override
  Future onReceive(TorrentClient client, TorrentClientPeerInfo info, TorrentMessage message) {
    return new Future(() {
      if (message.id == TorrentMessage.DUMMY_SIGN_SHAKEHAND) {
        info.front.sendPort(_localPort).catchError((e) {
          print("wean : failed to sendPort");
        });
      } else if (message.id == TorrentMessage.SIGN_PORT) {
        MessagePort portMessage = message;
        _node.addBootNode(info.ip, portMessage.port);
      }
    });
  }

  @override
  Future onSignal(TorrentClient client, TorrentClientPeerInfo info, TorrentClientSignal message) {
    return new Future(() {});
  }

  @override
  Future onTick(TorrentClient client) {
    for (KGetPeerValue ainfo in _node.rawAnnounced) {
      if(ainfo.infoHash.id.length != client.infoHash.length) {
        break;
      }
      {
        bool isTarget = true;
        for(int i=0;i<ainfo.infoHash.id.length;i++) {
          if(ainfo.infoHash.id[i] != client.infoHash[i]) {
            isTarget = false;
            break;
          }
        }
        if(isTarget == false) {
          break;
        }
      }
      print("--####-#### find dht #---------${ainfo.ipAsString}, ${ainfo.port}-----------");
      client.putTorrentPeerInfoFromTracker(ainfo.ipAsString, ainfo.port);
    }
    return new Future(() {});
  }

  Future _startPortMap() {
    _upnpPortMapClient.numOfRetry = 0;
    _upnpPortMapClient.basePort = _localPort;
    _upnpPortMapClient.localAddress = _localIp;
    _upnpPortMapClient.localPort = _localPort;
    return _upnpPortMapClient.startPortMap(reuseRouter: true, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_UDP);
  }
}
