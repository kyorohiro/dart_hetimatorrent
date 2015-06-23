library hetimatorrent.torrent.clientfront;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../util/peeridcreator.dart';
import '../message/message.dart';
import '../util/shufflelinkedlist.dart';
import 'torrentclient.dart';

class TorrentClientFront {
  List<int> _peerId = [];
  List<int> _infoHash = [];

  EasyParser _parser = null;
  HetiSocket _socket = null;
  bool handshaked = false;

  String ip = "";
  int port = 0;
  int speed = 0; //per sec bytes
  int downloadedBytesFromMe = 0; // Me is Hetima
  int uploadedBytesToMe = 0; // Me is Hetima
  int chokedFromMe = 0; // Me is Hetima
  int chokedToMe = 0; // Me is Hetima

  static Future<TorrentClientFront> connect(HetiSocketBuilder _builder, TorrentClientPeerInfo info, List<int> infoHash, [List<int> peerId = null]) {
    return new Future(() {
      HetiSocket socket = _builder.createClient();
      return socket.connect(info.ip, info.port).then((HetiSocket socket) {
        return new TorrentClientFront(socket, info.ip, info.port, socket.buffer, infoHash, peerId);
      });
    });
  }

  TorrentClientFront(HetiSocket socket, String ip, int port, HetimaReader reader, List<int> infoHash, List<int> peerId) {
    if (peerId == null) {
      _peerId.addAll(PeerIdCreator.createPeerid("heti69"));
    } else {
      _peerId.addAll(peerId);
    }
    _infoHash.addAll(infoHash);
    _socket = socket;
    _parser = new EasyParser(reader);
    handshaked = false;
  }

  StreamController<TorrentMessage> stream = new StreamController();
  Stream<TorrentMessage> get onReceiveEvent => stream.stream;

  Future<TorrentMessage> parse() {
    if (handshaked == false) {
      return TorrentMessage.parseHandshake(_parser).then((TorrentMessage message) {
        handshaked = true;
        return message;
      });
    } else {
      return TorrentMessage.parseBasic(_parser);
    }
  }

  void startReceive() {
    a() {
      new Future(() {
        parse().then((TorrentMessage message) {
          stream.add(message);
          a();
        });
      }).catchError((e) {
        stream.addError(e);
      });
    }
    a();
  }

  Future sendHandshake() {
    MessageHandshake message = new MessageHandshake(MessageHandshake.ProtocolId, [0, 0, 0, 0, 0, 0, 0, 0], _infoHash, _peerId);
    return message.encode().then((List<int> v) {
      return _socket.send(v).then((HetiSendInfo info) {
        return {};
      });
    });
  }
  
  Future sendBitfield(List<int> bitfield) {
    MessageBitfield message = new MessageBitfield(bitfield);
    return message.encode().then((List<int> v) {
      return _socket.send(v).then((HetiSendInfo info) {
        return {};
      });
    });
  }

  Future sendChoke() {
    MessageChoke message = new MessageChoke();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        return {};
      });
    });
  }

  Future sendUnchoke() {
    MessageUnchoke message = new MessageUnchoke();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        return {};
      });
    });
  }
  
  Future sendInterested() {
    MessageInterested message = new MessageInterested();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info){
        return {};
      });
    });
  }
  
  Future sendNotInterested() {
    MessageNotInterested message = new MessageNotInterested();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        return {};
      });
    });
  }
  
  Future sendCancel(int index, int begin, int length) {
    MessageCancel message = new MessageCancel(index, begin, length);
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        return {};
      });
    });
  }
  
  Future sendHave(int index) {
    MessageHave message = new MessageHave(index);
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        return {};
      });
    });
  }
  
  Future sendPort(int port) {
    MessagePort message = new MessagePort(port);
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        return {};
      });
    });
  }
  
  Future sendPiece(int index, int begin, List<int> content) {
    MessagePiece message = new MessagePiece(index, begin, content);
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        return {};
      });
    });
  }
  
  Future sendRequest(int index, int begin, int length) {
    MessageRequest message = new MessageRequest(index, begin, length);
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        return {};
      });
    });
  }
  
}

