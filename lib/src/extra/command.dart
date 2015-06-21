library hetimatorrent.extra.command;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
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

