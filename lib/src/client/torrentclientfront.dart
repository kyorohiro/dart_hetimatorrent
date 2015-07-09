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
  static const int STATE_NONE = 0;
  static const int STATE_ON = 1;
  static const int STATE_OFF = 2;
  List<int> _peerId = [];
  List<int> _infoHash = [];

  EasyParser _parser = null;
  HetiSocket _socket = null;
  bool handshaked = false;

  String _peerIp = "";
  int _peerPort = 0;
  int speed = 0; //per sec bytes
  int downloadedBytesFromMe = STATE_NONE; // Me is Hetima
  int uploadedBytesToMe = STATE_NONE; // Me is Hetima
  int chokedFromMe = STATE_NONE; // Me is Hetima
  int chokedToMe = STATE_NONE; // Me is Hetima

  int _unchokedStartTime = 0;
  int _uploadedBytesFromUnchokedStartTime = 0;

  int get unchokedStartTime => _unchokedStartTime;
  int get uploadSpeedFromUnchokeFromMe => _uploadedBytesFromUnchokedStartTime~/(new DateTime.now().millisecondsSinceEpoch - _unchokedStartTime);

  bool _handshakedToMe = false;
  bool _handshakedFromMe = false;
  bool get handshakeToMe => _handshakedToMe;
  bool get handshakeFromMe => _handshakedFromMe;
  bool get isClose => _socket.isClosed;

  bool _amI = false;
  bool get amI => _amI;
  int _interestedToMe = STATE_NONE;
  int _interestedFromMe = STATE_NONE;
  int get interestedToMe => _interestedToMe;
  int get interestedFromMe => _interestedFromMe;

  Bitfield _bitfieldToMe = null;
  Bitfield _bitfieldFromMe = null;
  Bitfield get bitfieldToMe => _bitfieldToMe;
  Bitfield get bitfieldFromMe => _bitfieldFromMe;
  Map<String, Object> tmpForAI = {};

  StreamController<TorrentMessage> stream = new StreamController();
  Stream<TorrentMessage> get onReceiveEvent => stream.stream;

  StreamController<TorrentClientFrontSignal> _streamSignal = new StreamController.broadcast();
  Stream<TorrentClientFrontSignal> get onReceiveSignal => _streamSignal.stream;

  static Future<TorrentClientFront> connect(HetiSocketBuilder _builder, TorrentClientPeerInfo info, int bitfieldSize, List<int> infoHash, [List<int> peerId = null]) {
    return new Future(() {
      HetiSocket socket = _builder.createClient();
      return socket.connect(info.ip, info.portAcceptable).then((HetiSocket socket) {
        return new TorrentClientFront(socket, info.ip, info.portAcceptable, socket.buffer, bitfieldSize, infoHash, peerId);
      });
    });
  }

  TorrentClientFront(HetiSocket socket, String peerIp, int peerPort, HetimaReader reader, int bitfieldSize, List<int> infoHash, List<int> peerId) {
    if (peerId == null) {
      _peerId.addAll(PeerIdCreator.createPeerid("heti69"));
    } else {
      _peerId.addAll(peerId);
    }
    _peerIp = peerIp;
    _peerPort = peerPort;
    _infoHash.addAll(infoHash);
    _socket = socket;
    _parser = new EasyParser(reader);
    _handshakedFromMe = false;
    _handshakedToMe = false;
    _bitfieldToMe = new Bitfield(bitfieldSize, clearIsOne: false);
    _bitfieldFromMe = new Bitfield(bitfieldSize, clearIsOne: false);
    _socket.onClose().listen((HetiCloseInfo info) {
      _streamSignal.add(new TorrentClientFrontSignal()..id=TorrentClientFrontSignal.ID_CLOSE);
    });
  }

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
            case TorrentMessage.SIGN_PIECE:
              TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_PIECE_RECEIVE, [message]);
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
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_INTERESTED_SEND, [message]);
        return {};
      });
    });
  }

  Future sendNotInterested() {
    MessageNotInterested message = new MessageNotInterested();
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_NOTINTERESTED_SEND, [message]);
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
        TorrentClientFrontSignal.doEvent(this, TorrentClientFrontSignal.ACT_PIECE_SEND, [message]);
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

  static const REASON_OWN_CONNECTION = 2001;
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
  static const int ACT_PIECE_SEND = 5000 + TorrentMessage.SIGN_PIECE;
  static const int ACT_PIECE_RECEIVE = 6000 + TorrentMessage.SIGN_PIECE;
  static const ID_HANDSHAKED = 1;
  static const ID_CLOSE = 2;
  static const ID_PIECE_SEND  = ACT_PIECE_SEND;
  static const ID_PIECE_RECEIVE = ACT_PIECE_RECEIVE;

  int id = 0;
  int reason = 0;
  int v = 0;

  String toString() {
    return TorrentClientFrontSignal.toText(this);
  }


  static String toText(TorrentClientFrontSignal signal) {
    switch(signal.id) {
      case ID_HANDSHAKED:
        return "[ID] Handshaked ok(${signal.id})";
      case ID_CLOSE:
        return "[ID] Closed ${signal.id} ${signal.reason}";
      case ACT_HANDSHAKE_SEND:
        return "handshake send(${signal.id})";
      case ACT_HANDSHAKE_RECEIVE:
        return "handshake receive(${signal.id})";
      case ACT_CHOKE_SEND:
        return "choke send(${signal.id})";
      case ACT_CHOKE_RECEIVE:
        return "choke receive(${signal.id})";
      case ACT_UNCHOKE_SEND:
        return "unchoke send(${signal.id})";
      case ACT_UNCHOKE_RECEIVE:
        return "unchoke receive(${signal.id})";
      case ACT_INTERESTED_SEND:
        return "interested send(${signal.id})";
      case ACT_INTERESTED_RECEIVE:
        return "interested receive(${signal.id})";
      case ACT_NOTINTERESTED_SEND:
        return "notinterested send(${signal.id})";
      case ACT_NOTINTERESTED_RECEIVE:
        return "notinterested receive(${signal.id})";
      case ACT_BITFIELD_SEND:
        return "bitfield send(${signal.id})";
      case ACT_BITFIELD_RECEIVE:
        return "bitfield receive(${signal.id})";
      default:
        return "other(${signal.id})";
    }
  }

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
        front.chokedFromMe = TorrentClientFront.STATE_ON;
        front._unchokedStartTime = new DateTime.now().millisecondsSinceEpoch;
        front._uploadedBytesFromUnchokedStartTime = 0;
        break;
      case ACT_UNCHOKE_SEND:
        front.chokedFromMe = TorrentClientFront.STATE_OFF;
        break;
      case ACT_CHOKE_RECEIVE:
        front.chokedToMe = TorrentClientFront.STATE_ON;
        break;
      case ACT_UNCHOKE_RECEIVE:
        front.chokedToMe = TorrentClientFront.STATE_OFF;
        break;       
      case ACT_INTERESTED_SEND:
        front._interestedFromMe = TorrentClientFront.STATE_ON;
        break;
      case ACT_NOTINTERESTED_SEND:
        front._interestedFromMe = TorrentClientFront.STATE_OFF;
        break;
      case ACT_INTERESTED_RECEIVE:
        front._interestedToMe = TorrentClientFront.STATE_ON;
        break;
      case ACT_NOTINTERESTED_RECEIVE:
        front._interestedToMe = TorrentClientFront.STATE_OFF;
        break;
      case ACT_BITFIELD_RECEIVE:
        MessageBitfield messageBitfile = args[0];
        front._bitfieldToMe.writeByte(messageBitfile.bitfield);
        break;
      case ACT_BITFIELD_SEND:
        front._bitfieldFromMe.writeByte(args[0]);
        break;
      case ACT_PIECE_SEND:
        front.uploadedBytesToMe += (args[0] as MessagePiece).content.length;
        front._uploadedBytesFromUnchokedStartTime += (args[0] as MessagePiece).content.length;
        front._streamSignal.add(new TorrentClientFrontSignal()
        ..id = TorrentClientFrontSignal.ID_PIECE_SEND
        ..reason = 0
        ..v=(args[0] as MessagePiece).content.length);
        break;
      case ACT_PIECE_RECEIVE:
        front.downloadedBytesFromMe += (args[0] as MessagePiece).content.length;
        front._streamSignal.add(new TorrentClientFrontSignal()
        ..id = TorrentClientFrontSignal.ID_PIECE_RECEIVE
        ..reason = 0
        ..v=(args[0] as MessagePiece).content.length);
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
