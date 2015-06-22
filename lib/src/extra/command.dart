library hetimatorrent.extra.command;

import 'dart:async';
import '../client/torrentclient.dart';
import '../client/torrentclientfront.dart';

import 'torrentengine.dart';

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
      engine.torrentClient.localAddress = localIp;
      engine.torrentClient.port = localPort;
      return engine.torrentClient.start().then((_) {
        return new CommandResult("started ${engine.torrentClient.localAddress} ${engine.torrentClient.port}");
      });
    });
  }
}

class GetPeerInfoCommand extends TorrentEngineCommand {
  String localIp = "";
  int localPort = 0;

  GetPeerInfoCommand() {
  }

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
      for(TorrentClientPeerInfo info in engine.torrentClient.peerInfos) {
        buffer.writeln("${info.id},ip:${info.ip},port:${info.port},speed:${info.speed},ubm:${info.uploadedBytesToMe},dfm:${info.downloadedBytesFromMe},ctm:${info.chokedToMe},cfm:${info.chokedFromMe}");
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
      return engine.torrentClient.connect(engine.socketBuilder, info, engine.torrentClient.infoHash).then((TorrentClientFront front) {
        return new CommandResult("connected");
      });
    });
  }
}

class HandshakeCommand extends TorrentEngineCommand {
  int _id =0;
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
      return info.front.sendHandshake().then((_){
        return new CommandResult("sended handshake");        
      });
    });
  }
}

