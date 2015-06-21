library hetimatorrent.torrent.client;

import 'dart:core';
import 'dart:async';
import 'dart:typed_data' as type;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../util/bencode.dart';
import '../util/peeridcreator.dart';
import '../message/torrentmessage.dart';
import '../message/messagehandshake.dart';
import '../message/messagebitfield.dart';
import '../util/shufflelinkedlist.dart';

class TorrentClientManager {
  List<int> _peerId = [];

  EasyParser _parser = null;

  TorrentClientManager(HetimaReader reader, [List<int> peerId = null]) {
    if (peerId == null) {
      _peerId.addAll(PeerIdCreator.createPeerid("heti69"));
    } else {
      _peerId.addAll(peerId);
    }
    _parser = new EasyParser(reader);
  }

  StreamController<TorrentMessage> stream = new StreamController();

  Stream<TorrentMessage> get onReceiveEvent => stream.stream;

  parser() {
    MessageHandshake.decode(_parser).then((MessageHandshake shakeEvent) {
      stream.add(shakeEvent);
    }).catchError((e) {
      return MessageBitfield.decode(_parser).then((MessageBitfield bitfield) {
        ;
      });
    }).catchError((e) {});
  }
}


class TorrentClient {
  HetiServerSocket _server = null;
  HetiSocketBuilder _builder = null;

  String localAddress = "0.0.0.0";
  int port = 8080;

  List<HetiSocket> _managedSocketList = [];

  TorrentClientPeerInfoList _peerInfos;
  List<TorrentClientPeerInfo>  get peerInfos => _peerInfos.peerInfos.sequential;

  TorrentClient(HetiSocketBuilder builder) {
    this._builder = builder;
    _peerInfos = new TorrentClientPeerInfoList();
  }

  void putTrackerTorrentPeer(String ip, int port, {peerId: ""}) {
    _peerInfos.putFormTrackerPeerInfo(ip, port, peerId: peerId);
  }

  
  Future start() {
    return _builder.startServer(localAddress, port).then((HetiServerSocket serverSocket) {
      _server = serverSocket;
      _server.onAccept().listen((HetiSocket socket) {
        return null;
      });
      return {};
    });
  }

  Future stop() {
    _server.close();
    for (HetiSocket s in _managedSocketList) {
      s.close();
    }
    return new Future(() {
      return {};
    });
  }
}


class TorrentClientPeerInfoList {
  ShuffleLinkedList<TorrentClientPeerInfo> peerInfos;

  TorrentClientPeerInfoList() {
    peerInfos = new ShuffleLinkedList();
  }

  
  void putFormTrackerPeerInfo(String ip, int port, {peerId: ""}) {
    for (int i = 0; i < peerInfos.length; i++) {
      TorrentClientPeerInfo info = peerInfos.getSequential(i);
      if (info.ip == ip || info.port == port) {
        // alredy added in peerinfo
        return;
      }
    }
    peerInfos.addLast(new TorrentClientPeerInfo(ip, port, peerId: peerId));
  }
}


class TorrentClientPeerInfo {
  static int nid = 0;
  int id = 0;
  String ip = "";
  int port = 0;
  int speed = 0; //per sec bytes
  int downloadedBytesFromMe = 0; // Me is Hetima
  int uploadedBytesToMe = 0; // Me is Hetima
  int chokedFromMe = 0; // Me is Hetima
  int chokedToMe = 0; // Me is Hetima

  TorrentClientPeerInfo(String ip, int port, {peerId: ""}) {
    this.ip = ip;
    this.port = port;
    this.id = ++nid;
  }
}
