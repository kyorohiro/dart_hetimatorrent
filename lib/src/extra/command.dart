library hetimatorrent.extra.command;

import 'dart:async';
import '../client/torrentclientfront.dart';

import 'torrentengine.dart';
import '../client/torrentclientpeerinfo.dart';
import 'package:hetimacore/hetimacore.dart';

class StartTorrentClientCommand extends TorrentEngineCommand {
  String localIp = "";
  int localPort = 0;

  StartTorrentClientCommand(String localIp, int localPort) {
    this.localIp = localIp;
    this.localPort = localPort;
  }

  static String get help => "${name} [string:ip] [int:port] : start torrent client.";
  static get name => "startTorrent";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new StartTorrentClientCommand(list[0], int.parse(list[1]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      return engine.torrentClient.start(localIp, localPort).then((_) {
        return new CommandResult("started ${engine.torrentClient.localAddress} ${engine.torrentClient.localPort}");
      });
    });
  }
}

class GoTorrentAICommand extends TorrentEngineCommand {

  bool usePortMap = false;
  GoTorrentAICommand(bool usePortMap) {
    this.usePortMap = usePortMap;
  }

  static String get help => "${name} [true/false:usePortMap]: go ai";
  static get name => "goTorrentAI";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new GoTorrentAICommand("true" == list[0]);
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      return engine.start(usePortMap:usePortMap);
    });
  }
}

class StopTorrentClientCommand extends TorrentEngineCommand {

  StopTorrentClientCommand() {
  }

  static String get help => "${name}: stop torrent client.";
  static get name => "stopTorrent";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new StopTorrentClientCommand();
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      if(engine.torrentClient != null) {
       return  engine.torrentClient.stop().then((_){
        return new CommandResult("stopped");
       });
      } else {
        return new CommandResult("already stopped");
      }
    });
  }
}
class GetPeerInfoCommand extends TorrentEngineCommand {
  String localIp = "";
  int localPort = 0;

  GetPeerInfoCommand() {}

  static String get help => "${name}: get peer info command.";
  static get name => "getPeerInfo";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new GetPeerInfoCommand();
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      StringBuffer buffer = new StringBuffer();
      for (TorrentClientPeerInfo info in engine.torrentClient.peerInfos) {
        buffer
            .writeln("${info.id},ip:${info.ip},port:${info.portAcceptable},speed:${info.speed},ubm:${info.uploadedBytesToMe},dfm:${info.downloadedBytesFromMe},ctm:${info.chokedToMe},cfm:${info.chokedFromMe}");
      }
      return new CommandResult("${buffer.toString()}");
    });
  }
}

class ConnectCommand extends TorrentEngineCommand {
  int _id = 0;

  ConnectCommand(int id) {
    this._id = id;
  }

  static String get help => "${name} [id]:";
  static get name => "connect";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new ConnectCommand(int.parse(list[0]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return engine.torrentClient.connect(info).then((TorrentClientFront front) {
        return new CommandResult("connected");
      });
    });
  }
}

class HandshakeCommand extends TorrentEngineCommand {
  int _id = 0;
  HandshakeCommand(int id) {
    _id = id;
  }

  static String get help => "${name} [number]:";
  static get name => "handshake";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new HandshakeCommand(int.parse(list[0]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      StringBuffer buffer = new StringBuffer();
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendHandshake().then((_) {
        return new CommandResult("sended handshake");
      });
    });
  }
}

class BitfieldCommand extends TorrentEngineCommand {
  int _id = 0;
  BitfieldCommand(int id) {
    _id = id;
  }

  static String get help => "${name} [number]:";
  static get name => "bitfield";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new BitfieldCommand(int.parse(list[0]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendBitfield(engine.torrentClient.targetBlock.bitfield).then((_) {
        return new CommandResult("sended bitfield");
      });
    });
  }
}

class RequestCommand extends TorrentEngineCommand {
  int _id = 0;
  int _index = 0;
  int _begin = 0;
  int _length = 0;
  RequestCommand(int id, int index, int begin, int length) {
    _id = id;
    _index = index;
    _begin = begin;
    _length = length;
  }

  static String get help => "${name} [id] [index] [begin] [length]:";
  static get name => "request";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new RequestCommand(int.parse(list[0]), int.parse(list[1]), int.parse(list[2]), int.parse(list[3]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendRequest(_index, _begin, _length).then((_) {
        return new CommandResult("sended request");
      });
    });
  }
}

class PieceCommand extends TorrentEngineCommand {
  int _id = 0;
  int _index = 0;
  int _begin = 0;
  int _length = 0;
  PieceCommand(int id, int index, int begin, int length) {
    _id = id;
    _index = index;
    _begin = begin;
    _length = length;
  }

  static String get help => "${name} [id] [index] [begin] [length]:";
  static get name => "piece";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new PieceCommand(int.parse(list[0]), int.parse(list[1]), int.parse(list[2]), int.parse(list[3]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return engine.torrentClient.targetBlock.readBlock(_index).then((ReadResult result) {
        return info.front.sendPiece(_index, _begin, result.buffer.sublist(_begin, _begin + _length)).then((_) {
          return new CommandResult("sended piece");
        });
      });
    });
  }
}

class CancelCommand extends TorrentEngineCommand {
  int _id = 0;
  int _index = 0;
  int _begin = 0;
  int _length = 0;
  CancelCommand(int id, int index, int begin, int length) {
    _id = id;
    _index = index;
    _begin = begin;
    _length = length;
  }

  static String get help => "${name} [id] [index] [begin] [length]:";
  static get name => "cancel";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new CancelCommand(int.parse(list[0]), int.parse(list[1]), int.parse(list[2]), int.parse(list[3]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendCancel(_index, _begin, _length).then((_) {
        return new CommandResult("sended cancel");
      });
    });
  }
}

class HaveCommand extends TorrentEngineCommand {
  int _id = 0;
  int _index = 0;
  HaveCommand(int id, int index) {
    _id = id;
    _index = index;
  }

  static String get help => "${name} [id] [index]";
  static get name => "have";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new HaveCommand(int.parse(list[0]), int.parse(list[1]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendHave(_index).then((_) {
        return new CommandResult("sended have");
      });
    });
  }
}

class ChokeCommand extends TorrentEngineCommand {
  int _id = 0;
  ChokeCommand(int id) {
    _id = id;
  }

  static String get help => "${name} [id]";
  static get name => "choke";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new ChokeCommand(int.parse(list[0]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendChoke().then((_) {
        return new CommandResult("sended have");
      });
    });
  }
}

class UnchokeCommand extends TorrentEngineCommand {
  int _id = 0;
  UnchokeCommand(int id) {
    _id = id;
  }

  static String get help => "${name} [id]";
  static get name => "unchoke";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new UnchokeCommand(int.parse(list[0]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendUnchoke().then((_) {
        return new CommandResult("sended unchoke");
      });
    });
  }
}


class InterestedCommand extends TorrentEngineCommand {
  int _id = 0;
  InterestedCommand(int id) {
    _id = id;
  }

  static String get help => "${name} [id]";
  static get name => "interested";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new InterestedCommand(int.parse(list[0]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendInterested().then((_) {
        return new CommandResult("sended unchoke");
      });
    });
  }
}


class NotInterestedCommand extends TorrentEngineCommand {
  int _id = 0;
  NotInterestedCommand(int id) {
    _id = id;
  }

  static String get help => "${name} [id]";
  static get name => "notinterested";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new NotInterestedCommand(int.parse(list[0]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendNotInterested().then((_) {
        return new CommandResult("sended unchoke");
      });
    });
  }
}


class PortCommand extends TorrentEngineCommand {
  int _id = 0;
  int _port = 0;
  PortCommand(int id, int port) {
    _id = id;
    _port = port;
  }

  static String get help => "${name} [id] [port]";
  static get name => "port";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new PortCommand(int.parse(list[0]), int.parse(list[1]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      TorrentClientPeerInfo info = engine.torrentClient.getPeerInfoFromId(_id);
      return info.front.sendPort(_port).then((_) {
        return new CommandResult("sended unchoke");
      });
    });
  }
}
