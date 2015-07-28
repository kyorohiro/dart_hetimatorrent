library hetimatorrent.torrent.clientfront;

import 'dart:core';
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import '../util/peeridcreator.dart';
import 'message/message.dart';
import 'torrentclientpeerinfo.dart';
import '../util/bitfield.dart';
import 'torrentclientmessage.dart';

class TorrentClientFront {
  static const int STATE_NONE = 0;
  static const int STATE_ON = 1;
  static const int STATE_OFF = 2;
  List<int> _myPeerId = [];
  List<int> _targetPeerId = [];
  List<int> get targetPeerId => new List.from(_targetPeerId);
  List<int> _infoHash = [];
  List<int> _targetProtocolId = [];

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
  int get uploadSpeedFromUnchokeFromMe => _uploadedBytesFromUnchokedStartTime ~/ (new DateTime.now().millisecondsSinceEpoch - _unchokedStartTime);

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

  List<MessageRequest> currentRequesting = [];
  StreamController<TorrentMessage> stream = new StreamController();
  Stream<TorrentMessage> get onReceiveEvent => stream.stream;

  StreamController<TorrentClientSignal> _streamSignal = new StreamController.broadcast();
  Stream<TorrentClientSignal> get onReceiveSignal => _streamSignal.stream;

  int _lastRequestIndex = null;
  int get lastRequestIndex => _lastRequestIndex;

  static int debugIdSeed = 0;
  int _debugId = 0;
  
  List<int> _reseved = [0, 0, 0, 0, 0, 0, 0, 0];
  List<int> get reseved => new List.from(_reseved);
  set reseved( List<int>  v) {
    if(v.length != 8) {
      throw {};
    }
    _reseved.clear();
    _reseved.addAll(v);
  }
  static Future<TorrentClientFront> connect(HetiSocketBuilder _builder, TorrentClientPeerInfo info, int bitfieldSize, List<int> infoHash, {List<int> peerId:null,List<int> reseved:null}) {
    return new Future(() {
      HetiSocket socket = _builder.createClient();
      return socket.connect(info.ip, info.portAcceptable).then((HetiSocket socket) {
        return new TorrentClientFront(socket, info.ip, info.portAcceptable, socket.buffer, bitfieldSize, infoHash, peerId, reseved);
      });
    });
  }

  TorrentClientFront(HetiSocket socket, String peerIp, int peerPort, HetimaReader reader, int bitfieldSize, List<int> infoHash, List<int> peerId, List<int> reseved) {
    if (peerId == null) {
      _myPeerId.addAll(PeerIdCreator.createPeerid("heti69"));
    } else {
      _myPeerId.addAll(peerId);
    }

    if (reseved == null) {
      this._reseved = [0, 0, 0, 0, 0, 0, 0, 0];
    } else {
      this._reseved.clear();
      this._reseved.addAll(reseved);
    }

    _debugId = debugIdSeed++;
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
      TorrentClientFrontNerve.doClose(this, 0);
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
          TorrentClientFrontNerve.doReceiveMessage(this, message);
          stream.add(message);
          a();
        });
      }).catchError((e) {
        stream.addError(e);
        close();
      });
    }
    a();
  }

  Future sendHandshake({List<int> reseved: null}) {
    if (reseved == null) {
      reseved = new List.from(_reseved);
    }
    MessageHandshake message = new MessageHandshake(MessageHandshake.ProtocolId, reseved, _infoHash, _myPeerId);
    return sendMessage(message);
  }

  Future sendBitfield(List<int> bitfield) {
    MessageBitfield message = new MessageBitfield(bitfield);
    return sendMessage(message);
  }

  Future sendChoke() {
    MessageChoke message = new MessageChoke();
    return sendMessage(message);
  }

  Future sendUnchoke() {
    MessageUnchoke message = new MessageUnchoke();
    return sendMessage(message);
  }

  Future sendInterested() {
    MessageInterested message = new MessageInterested();
    return sendMessage(message);
  }

  Future sendNotInterested() {
    MessageNotInterested message = new MessageNotInterested();
    return sendMessage(message);
  }

  Future sendCancel(int index, int begin, int length) {
    MessageCancel message = new MessageCancel(index, begin, length);
    return sendMessage(message);
  }

  Future sendHave(int index) {
    MessageHave message = new MessageHave(index);
    return sendMessage(message);
  }

  Future sendPort(int port) {
    MessagePort message = new MessagePort(port);
    return sendMessage(message);
  }

  Future sendPiece(int index, int begin, List<int> content) {
    MessagePiece message = new MessagePiece(index, begin, content);
    return sendMessage(message);
  }

  Future sendRequest(int index, int begin, int length) {
    MessageRequest message = new MessageRequest(index, begin, length);
    return sendMessage(message);
  }

  Future sendMessage(TorrentMessage message) {
    return message.encode().then((List<int> data) {
      return _socket.send(data).then((HetiSendInfo info) {
        TorrentClientFrontNerve.doSendMessage(this, message);
        return {};
      });
    });
  }

  void close() {
    print("###[${_debugId}][${_peerIp}:${_peerPort}] close");
    _socket.close();
    TorrentClientFrontNerve.doClose(this, 0);
  }
}

//
//
//
class TorrentClientFrontNerve {
  int id = 0;
  int reason = 0;
  int v = 0;

  String toString() {
    return "${id} ${reason} ${v}";
  }

  static void doReceiveMessage(TorrentClientFront front, TorrentMessage message) {
    print("###[${front._debugId} ${front._peerIp}:${front._peerPort}] receive ${message.toString()}");
    switch (message.id) {
      case TorrentMessage.DUMMY_SIGN_SHAKEHAND:
        front._handshakedToMe = true;
        front._targetPeerId.clear();
        front._targetPeerId.addAll((message as MessageHandshake).peerId);
        front._targetProtocolId.addAll((message as MessageHandshake).protocolId);
        _signalHandshake(front);
        _signalHandshakeOwnConnectCheck(front, message);
        _signalHandshakeInfoHashCheck(front, message);
        break;
      case TorrentMessage.SIGN_CHOKE:
        front.chokedToMe = TorrentClientFront.STATE_ON;
        break;
      case TorrentMessage.SIGN_UNCHOKE:
        front.chokedToMe = TorrentClientFront.STATE_OFF;
        break;
      case TorrentMessage.SIGN_INTERESTED:
        front._interestedToMe = TorrentClientFront.STATE_ON;
        break;
      case TorrentMessage.SIGN_NOTINTERESTED:
        front._interestedToMe = TorrentClientFront.STATE_OFF;
        break;
      case TorrentMessage.SIGN_BITFIELD:
        MessageBitfield messageBitfile = message;
        front._bitfieldToMe.writeBytes(messageBitfile.bitfield);
        break;
      case TorrentMessage.SIGN_HAVE:
        MessageHave messageHave = message;
        front._bitfieldToMe.setIsOn(messageHave.index, true);
        break;
      case TorrentMessage.SIGN_PIECE:
        {
          MessagePiece req = message;
          List<MessageRequest> removeTarge = [];
          for (MessageRequest mes in front.currentRequesting) {
            if (mes.begin == req.begin && mes.index == req.index && mes.length == req.content.length) {
              removeTarge.add(mes);
            }
          }
          for (MessageRequest rm in removeTarge) {
            front.currentRequesting.remove(rm);
          }
        }
        front.downloadedBytesFromMe += (message as MessagePiece).content.length;
        front._streamSignal.add(new TorrentClientSignalWithFront(front, TorrentClientSignal.ID_PIECE_RECEIVE, 0, "", (message as MessagePiece).content.length));
        break;
    }
  }

  static void doSendMessage(TorrentClientFront front, TorrentMessage message) {
    print("###[${front._peerIp}:${front._peerPort} ${front.isClose}] send ${message.toString()}");
    switch (message.id) {
      case TorrentMessage.DUMMY_SIGN_SHAKEHAND:
        front._handshakedFromMe = true;
        _signalHandshake(front);
        break;
      case TorrentMessage.SIGN_CHOKE:
        front.chokedFromMe = TorrentClientFront.STATE_ON;
        front._unchokedStartTime = new DateTime.now().millisecondsSinceEpoch;
        front._uploadedBytesFromUnchokedStartTime = 0;
        break;
      case TorrentMessage.SIGN_UNCHOKE:
        front.chokedFromMe = TorrentClientFront.STATE_OFF;
        break;
      case TorrentMessage.SIGN_INTERESTED:
        front._interestedFromMe = TorrentClientFront.STATE_ON;
        break;
      case TorrentMessage.SIGN_NOTINTERESTED:
        front._interestedFromMe = TorrentClientFront.STATE_OFF;
        break;
      case TorrentMessage.SIGN_BITFIELD:
        MessageBitfield messageBitfile = message;
        front._bitfieldFromMe.writeBytes(messageBitfile.bitfield);
        break;
      case TorrentMessage.SIGN_PIECE:
        front.uploadedBytesToMe += (message as MessagePiece).content.length;
        front._uploadedBytesFromUnchokedStartTime += (message as MessagePiece).content.length;
        front._streamSignal.add(new TorrentClientSignalWithFront(front, TorrentClientSignal.ID_PIECE_SEND, 0, "", (message as MessagePiece).content.length));
        break;
      case TorrentMessage.SIGN_REQUEST:
        MessageRequest resestMessage = message;
        front.currentRequesting.add(message);
        front._lastRequestIndex = resestMessage.index;
        break;
    }
  }

  static void _signalHandshakeInfoHashCheck(TorrentClientFront front, TorrentMessage message) {
    if (message.id != TorrentMessage.DUMMY_SIGN_SHAKEHAND) {
      return;
    }
    MessageHandshake handshakeMessage = message;
    if (handshakeMessage.infoHash != front._infoHash) {
      doClose(front, TorrentClientSignal.REASON_UNMANAGED_INFOHASH);
    }
  }

  static void _signalHandshake(TorrentClientFront front) {
    if (front._handshakedFromMe == true && front._handshakedToMe == true) {
      front._streamSignal.add(new TorrentClientSignalWithFront(front, TorrentClientSignal.ID_HANDSHAKED, 0, ""));
    }
  }

  static void _signalHandshakeOwnConnectCheck(TorrentClientFront front, TorrentMessage message) {
    if (message.id != TorrentMessage.DUMMY_SIGN_SHAKEHAND) {
      return;
    }
    MessageHandshake handshakeMessage = message;
    if (handshakeMessage.peerId == front._myPeerId) {
      front._amI = true;
      doClose(front, TorrentClientSignal.REASON_OWN_CONNECTION);
    }
  }

  static void doClose(TorrentClientFront front, int reason) {
    front._streamSignal.add(new TorrentClientSignalWithFront(front, TorrentClientSignal.ID_CLOSE, reason, ""));
  }
}
