library hetimatorrent.extra.trackercommand;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'torrentengine.dart';

class TrackerCommand extends TorrentEngineCommand {
  static String get help => "${name} [port] [event]: evet:[started,stopped,completed]";

  static String get name => "requestTracker";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new TrackerCommand(int.parse(list[0]), list[1]);
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  int port = 0;
  String event = "";

  TrackerCommand(int port, String event) {
    this.port = port;
    this.event = event;
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      engine.trackerClient.event = event;
      engine.trackerClient.peerport = port;
      return engine.trackerClient.request().then((TrackerRequestResult result) {
        StringBuffer buffer = new StringBuffer();
        buffer.writeln("interval:${result.response.interval}");
        for (TrackerPeerInfo info in result.response.peers) {
          buffer.writeln("ip:${info.ipAsString}, port:${info.portdAsString},");
          engine.torrentClient.putTrackerTorrentPeer(info.ipAsString, info.port);
        }
        return new CommandResult(buffer.toString());
      });
    });
  }
}
