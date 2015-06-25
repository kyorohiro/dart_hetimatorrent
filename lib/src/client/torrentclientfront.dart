library hetimatorrent.torrent.clientfront;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../util/peeridcreator.dart';
import '../message/message.dart';
import 'torrentclientpeerinfo.dart';
import '../util/bitfield.dart';

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

  bool _handshakedToMe = false;
  bool _handshakedFromMe = false;
  bool get handshakeToMe => _handshakedToMe;
  bool get handshakeFromMe => _handshakedFromMe;
  bool get isClose => _socket.isClosed;

  bool _amI = false;
  bool get amI => _amI;
  bool _interestedToMe = false;
  bool _interestedFromMe = false;
  bool get interestedToMe => _interestedToMe;
  bool get interestedFromMe => _interestedFromMe;
  
  Bitfield _bitfieldToMe = null;
  Bitfield get bitfieldToMe => _bitfieldToMe;

  Map<String, Object> tmpForAI = {};

  static Future<TorrentClientFront> connect(HetiSocketBuilder _builder, TorrentClientPeerInfo info, int bitfieldSize, List<int> infoHash,  [List<int> peerId = null]) {
    return new Future(() {
      HetiSocket socket = _builder.createClient();
      return socket.connect(info.ip, info.port).then((HetiSocket socket) {
        return new TorrentClientFront(socket, info.ip, info.port, socket.buffer, bitfieldSize, infoHash, peerId);
      });
    });
  }

  TorrentClientFront(HetiSocket socket, String ip, int port, HetimaReader reader, int bitfieldSize, List<int> infoHash, List<int> peerId) {
    if (peerId == null) {
      _peerId.addAll(PeerIdCreator.createPeerid("heti69"));
    } else {
      _peerId.addAll(peerId);
    }
    _infoHash.addAll(infoHash);
    _socket = socket;
    _parser = new EasyParser(reader);
    _handshakedFromMe = false;
    _handshakedToMe = false;
    _bitfieldToMe = new Bitfield(bitfieldSize, clearIsOne:false);
  }

  StreamController<TorrentMessage> stream = new StreamController();
  Stream<TorrentMessage> get onReceiveEvent => stream.stream;

  StreamController<TorrentClientFrontSignal> _streamSignal = new StreamController.broadcast();
  Stream<TorrentClientFrontSignal> get onReceiveSignal => _streamSignal.stream;

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
          //
          // signal
          switch (message.id) {
            case TorrentMessage.DUMMY_SIGN_SHAKEHAND:
                TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_HANDSHAKE_RECEIVE, [message]);
              break;
            case TorrentMessage.SIGN_INTERESTED:
                TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_INTERESTED_RECEIVE, [message]);
              break;
            case TorrentMessage.SIGN_NOTINTERESTED:
                TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_NOTINTERESTED_RECEIVE, [message]);
              break;
            case TorrentMessage.SIGN_CHOKE:
                TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_CHOKE_RECEIVE, [message]);
              break;
            case TorrentMessage.SIGN_UNCHOKE:
                TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_UNCHOKE_RECEIVE, [message]);
              break;
            case TorrentMessage.SIGN_BITFIELD:
              TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_BITFIELD_RECEIVE, [message]);
              break;
          }

          //
          // event
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
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_HANDSHAKE_SEND, []);
        return {};
      });
    });
  }

  Future sendBitfield(List<int> bitfield) {
    MessageBitfield message = new MessageBitfield(bitfield);
    return message.encode().then((List<int> v) {
      return _socket.send(v).then((HetiSendInfo info) {
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_BITFIELD_SEND, [bitfield]);
        return {};
      });
    });
  }

  Future sendChoke() {
    MessageChoke message = new MessageChoke();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_CHOKE_SEND, []);
        return {};
      });
    });
  }

  Future sendUnchoke() {
    MessageUnchoke message = new MessageUnchoke();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_UNCHOKE_SEND, []);
        return {};
      });
    });
  }

  Future sendInterested() {
    MessageInterested message = new MessageInterested();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_INTERESTED_SEND, []);
        return {};
      });
    });
  }

  Future sendNotInterested() {
    MessageNotInterested message = new MessageNotInterested();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_NOTINTERESTED_SEND, []);
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

  void close() {
    _socket.close();
  }
}

//
//
//
class TorrentClientFrontSignal {
  static const ID_HANDSHAKED = 1;
  static const ID_CLOSE = 2;
  static const REASON_OWN_CONNECTION = 2001;
  int id = 0;
  int reason = 0;

  static const int ACT_HANDSHAKE_SEND = 5000 + TorrentMessage.DUMMY_SIGN_SHAKEHAND;
  static const int ACT_HANDSHAKE_RECEIVE = 6000 + TorrentMessage.DUMMY_SIGN_SHAKEHAND;
  static const int ACT_CHOKE_SEND = 5000 + TorrentMessage.SIGN_CHOKE;
  static const int ACT_CHOKE_RECEIVE = 6000 + TorrentMessage.SIGN_CHOKE;
  static const int ACT_UNCHOKE_SEND = 5000 + TorrentMessage.SIGN_UNCHOKE;
  static const int ACT_UNCHOKE_RECEIVE = 6000 + TorrentMessage.SIGN_UNCHOKE;
  static const int ACT_INTERESTED_SEND = 5000 + TorrentMessage.SIGN_INTERESTED;
  static const int ACT_INTERESTED_RECEIVE = 6000 + TorrentMessage.SIGN_INTERESTED;
  static const int ACT_NOTINTERESTED_SEND = 5000 + TorrentMessage.SIGN_NOTINTERESTED;
  static const int ACT_NOTINTERESTED_RECEIVE = 6000 + TorrentMessage.SIGN_NOTINTERESTED;
  static const int ACT_BITFIELD_SEND = 5000 + TorrentMessage.SIGN_BITFIELD;
  static const int ACT_BITFIELD_RECEIVE = 6000 + TorrentMessage.SIGN_BITFIELD;
  static void doEvent(TorrentClientFront front, int act, List<Object> args) {
    switch (act) {
      case ACT_HANDSHAKE_RECEIVE:
          front._handshakedToMe = true;
          _signalHandshake(front);
          _signalHandshakeOwnConnectCheck(front, args[0]);
        break;
      case ACT_HANDSHAKE_SEND:
          front._handshakedFromMe = true;
          _signalHandshake(front);
        break;
      case ACT_CHOKE_SEND:
          front._handshakedFromMe = true;
        break;
      case ACT_CHOKE_RECEIVE:
          front._handshakedToMe = true;
        break;
      case ACT_INTERESTED_SEND:
          front._interestedFromMe = true;
        break;
      case ACT_INTERESTED_RECEIVE:
          front._interestedToMe = true;
        break;
      case ACT_BITFIELD_RECEIVE: {
        MessageBitfield messageBitfile = args[0];
        front._bitfieldToMe.writeByte(messageBitfile.bitfield);
      }
        break;
    }
  }

  static void _signalHandshake(TorrentClientFront front) {
    if (front._handshakedFromMe == true && front._handshakedToMe == true) {
      front._streamSignal.add(new TorrentClientFrontSignal()..id = TorrentClientFrontSignal.ID_HANDSHAKED);
    }
  }

  static void _signalHandshakeOwnConnectCheck(TorrentClientFront front, TorrentMessage message) {
    if (message.id != TorrentMessage.DUMMY_SIGN_SHAKEHAND) {
      return;
    }
    MessageHandshake handshakeMessage = message;
    if (handshakeMessage.peerId == front._peerId) {
      front._amI = true;
      TorrentClientFrontSignal frontSignal = new TorrentClientFrontSignal()
        ..id = TorrentClientFrontSignal.ID_CLOSE
        ..reason = TorrentClientFrontSignal.REASON_OWN_CONNECTION;
      front._streamSignal.add(frontSignal);
    }
  }
}
