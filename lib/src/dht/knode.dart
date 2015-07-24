library hetimatorrent.dht.knode;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'krootingtable.dart';

import 'message/krpcping.dart';
import 'message/krpcfindnode.dart';
import 'message/krpcgetpeers.dart';
import 'kid.dart';
import 'dart:convert';
import '../util/shufflelinkedlist.dart';

import 'message/krpcmessage.dart';
import 'message/krpcping.dart';
import 'message/krpcfindnode.dart';
import 'message/krpcgetpeers.dart';
import 'message/krpcannounce.dart';
import 'kpeerinfo.dart';

class KNode extends Object with KrpcResponseInfo {
  HetiSocketBuilder _socketBuilder = null;
  HetiUdpSocket _udpSocket = null;
  KRootingTable _rootingtable = null;
  Map<String, EasyParser> buffers = {};
  KId _nodeId = null;
  KId get nodeId => _nodeId;
  List<SendInfo> queryInfo = [];
  KNodeAI _ai = null;
  KNode(HetiSocketBuilder socketBuilder, {int kBucketSize: 8, List<int> nodeIdAsList: null,KNodeAI ai:null}) {
    if (nodeIdAsList == null) {
      _nodeId = KId.createIDAtRandom();
    } else {
      _nodeId = new KId(nodeIdAsList);
    }
    this._socketBuilder = socketBuilder;
    this._rootingtable = new KRootingTable(kBucketSize);
    if(ai == null) {
      this._ai = new KNodeAI();
    } else {
      this._ai = ai;
    }
  }

  Future start({String ip: "0.0.0.0", int port: 28080}) {
    return new Future(() {
      if (_udpSocket != null) {
        throw {};
      }
      _udpSocket = this._socketBuilder.createUdpClient();
      return _udpSocket.bind(ip, port).then((int v) {
        _udpSocket.onReceive().listen((HetiReceiveUdpInfo info) {
          if (!buffers.containsKey("${info.remoteAddress}:${info.remotePort}")) {
            buffers["${info.remoteAddress}:${info.remotePort}"] = new EasyParser(new ArrayBuilder());
          }
          EasyParser parser = buffers["${info.remoteAddress}:${info.remotePort}"];
          
          //
          //
          KrpcMessage.decode(parser, this).then((KrpcMessage message) {
            if (message is KrpcResponse) {
              SendInfo rm = removeQueryNameFromTransactionId(UTF8.decode(message.rawMessageMap["t"]));
              _onReceiveResponse(info, message);
              rm._c.complete(message);
            } else if (message is KrpcQuery) {
              _onReceiveQuery(info, message);
            } else if(message is KrpcError){
              _onReceiveError(info, message);
            } else {
              _onReceiveUnknown(info, message);
            }
          }).catchError((e) {
            parser.last();
          });
          //
          
          _ai.start(this);
        });
      });
    });
  }

  _onReceiveQuery(HetiReceiveUdpInfo info, KrpcQuery message) {}
  _onReceiveResponse(HetiReceiveUdpInfo info, KrpcResponse message) {}
  _onReceiveError(HetiReceiveUdpInfo info, KrpcError message) {}
  _onReceiveUnknown(HetiReceiveUdpInfo info, KrpcMessage message) {}

  String getQueryNameFromTransactionId(String transactionId) {
    for (SendInfo si in queryInfo) {
      if (si._id == transactionId) {
        return si._act;
      }
    }
    return "";
  }
  SendInfo removeQueryNameFromTransactionId(String transactionId) {
    SendInfo re = null;
    for (SendInfo si in queryInfo) {
      if (si._id == transactionId) {
        re = si;
        break;
      }
    }
    queryInfo.remove(re);
    return re;
  }
  static int id = 0;
  Future sendPing(String ip, int port) {
    Completer c;
    new Future(() {
      KrpcPingQuery query = new KrpcPingQuery(UTF8.encode("p_${id}"), _nodeId.id);
      queryInfo.add(new SendInfo("p_${id}", "ping", c));
      return _udpSocket.send(query.messageAsBencode, ip, port);
    }).catchError(c.completeError);
    return c.future;
  }

  Future sendFindNode(String ip, int port, List<int> targetNodeId) {
    Completer c;
    new Future(() {
      KrpcFindNodeQuery query = new KrpcFindNodeQuery(UTF8.encode("p_${id}"), _nodeId.id, targetNodeId);
      //(UTF8.encode("p_${id}"), _nodeId.id);
      queryInfo.add(new SendInfo("p_${id}", "find_node", c));
      return _udpSocket.send(query.messageAsBencode, ip, port);
    }).catchError(c.completeError);
    return c.future;
  }

  Future sendGetPeers(String ip, int port, List<int> infoHash) {
    Completer c;
    new Future(() {
      KrpcGetPeersQuery query = new KrpcGetPeersQuery(UTF8.encode("p_${id}"), _nodeId.id, infoHash);
      //(UTF8.encode("p_${id}"), _nodeId.id);
      queryInfo.add(new SendInfo("p_${id}", "get_peers", c));
      return _udpSocket.send(query.messageAsBencode, ip, port);
    }).catchError(c.completeError);
    return c.future;
  }

  Future sendAnnouncePeer(String ip, int port, int implied_port,List<int> infoHash, List<int> opaqueToken) {
    Completer c;
    new Future(() {
      KrpcAnnouncePeerQuery query = new KrpcAnnouncePeerQuery(UTF8.encode("p_${id}"), _nodeId.id,
          implied_port, infoHash, port, opaqueToken);
      queryInfo.add(new SendInfo("p_${id}", "announce_peer", c));
      return _udpSocket.send(query.messageAsBencode, ip, port);
    }).catchError(c.completeError);
    return c.future;
  }
  Future stop() {
    return new Future(() {
      if (_udpSocket == null) {
        return null;
      } else {
        return _udpSocket.close();
      }
    }).whenComplete((){
      _ai.stop(this);
    });
  }
}

class KNodeAI {
  
  start(KNode node) {
  }
  
  stop(KNode node) {
    
  }

  maintenance(KNode node) {
    node._rootingtable.findNode(node._nodeId).then((List<KPeerInfo> infos) {
      for(KPeerInfo info in infos) {
        node.sendFindNode(info.ipAsString, info.port, node._nodeId.id);
      }
    });
  }

  onReceiveQuery(KNode node, HetiReceiveUdpInfo info, KrpcQuery query) {
    node._rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, query.queryingNodesId));
    switch(query.id) {
      case KrpcMessage.PING_QUERY:
        node.sendPing(info.remoteAddress, info.remotePort);
        break;
      case KrpcMessage.ANNOUNCE_QUERY:
        break;
      case KrpcMessage.FIND_NODE_QUERY:
        break;
      case KrpcMessage.GET_PEERS_QUERY:
        break;
      case KrpcMessage.NONE_QUERY:
        break;      
    }
  }

  onReceiveError(KNode node, HetiReceiveUdpInfo info, KrpcError message) {
    
  }

  onReceiveResponse(KNode node, HetiReceiveUdpInfo info, KrpcResponse response) {
    node._rootingtable.update(new KPeerInfo(info.remoteAddress, info.remotePort, response.queriedNodesId));
  }

  onReceiveUnknown(KNode node, HetiReceiveUdpInfo info, KrpcMessage message) {
    
  }
}

class SendInfo {
  String _id = "";
  String get id => _id;
  String _act = "";
  String get act => _act;

  int _time = 0;
  int get time => _time;

  Completer _c = null;
  SendInfo(String id, String act, Completer c) {
    this._id = id;
    this._c = c;
    this._act = act;
    this._time = new DateTime.now().millisecondsSinceEpoch;
  }
}
