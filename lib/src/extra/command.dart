library hetimatorrent.extra.command;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

abstract class TorrentEngineCommand {
  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null});
  static String get help => "";
}

class TorrentEngineCommandBuilder {
  Function builder = null; //TorrentEngineCommand builder(List<String> list);
  String help = "";
  TorrentEngineCommandBuilder(Function builder, String help) {
    this.builder = builder;
    this.help = help;
  }
}
class CommandResult {
  String message = "";
  CommandResult(String message) {
    this.message = message;
  }
}

class TorrentEngine {
  TorrentClient _torrentClient = null;
  TrackerClient _trackerClient = null;
  UpnpPortMapHelper _upnpPortMapClient = null;
  HetiSocketBuilder _builder = null;

  HetiSocketBuilder get socketBuilder => _builder;

  TorrentEngine._empty() {
    ;
  }

  static Future<TorrentEngine> createTorrentEngine(HetiSocketBuilder builder, TorrentFile torrentfile, {appid: "hetima_torrent_engine"}) {
    return new Future(() {
      TorrentEngine engine = new TorrentEngine._empty();
      return TrackerClient.createTrackerClient(builder, torrentfile).then((TrackerClient trackerClient) {
        engine._builder = builder;
        engine._trackerClient = trackerClient;
        engine._torrentClient = new TorrentClient(builder);
        engine._upnpPortMapClient = new UpnpPortMapHelper(builder, appid);
        return engine;
      });
    });
  }

  TrackerClient get trackerClient => this._trackerClient;
}

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
      engine._torrentClient.localAddress = localIp;
      engine._torrentClient.port = localPort;
      return engine._torrentClient.start().then((_) {
        return new CommandResult("started ${engine._torrentClient.localAddress} ${engine._torrentClient.port}");
      });
    });
  }
}

class StartUpnpPortMapCommand extends TorrentEngineCommand {
  String localIp = "";
  int localPort = 0;
  int globalPort = 0;

  StartUpnpPortMapCommand(String localIp, int localPort, int globalPort) {
    this.localIp = localIp;
    this.localPort = localPort;
    this.globalPort = globalPort;
  }

  static String get help => "${name} [localIp] [localPort] [globalPort]: request port map commaand";

  static String get name => "startPortMap";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new StartUpnpPortMapCommand(list[0], int.parse(list[1]), int.parse(list[2]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      engine._upnpPortMapClient.localAddress = localIp;
      engine._upnpPortMapClient.basePort = globalPort;
      engine._upnpPortMapClient.localPort = localPort;
      engine._upnpPortMapClient.numOfRetry = 0;
      return engine._upnpPortMapClient.startPortMap().then((StartPortMapResult result) {
        return new CommandResult("portmapped ${result.hashCode}");
      });
    });
  }
}

class StopUpnpPortMapCommand extends TorrentEngineCommand {
  int port = 0;
  StopUpnpPortMapCommand(int port) {
    this.port = port;
  }

  static String get help => "${name} [int:port]: request port map commaand";
  static String get name => "stopPortMap";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new StopUpnpPortMapCommand(int.parse(list[0]));
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      return engine._upnpPortMapClient.deleteAllPortMap([port]).then((DeleteAllPortMapResult result) {
        return new CommandResult("portmapped ${result.hashCode}");
      });
    });
  }
}

class GetUpnpPortMapInfoCommand extends TorrentEngineCommand {
  int port = 0;
  StopUpnpPortMapCommand(int port) {
    this.port = port;
  }

  static String get help => "${name} : request port map info";
  static String get name => "getPortMapInfo";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new GetUpnpPortMapInfoCommand();
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      return engine._upnpPortMapClient.getPortMapInfo().then((GetPortMapInfoResult result) {
        StringBuffer buffer = new StringBuffer();
        for (PortMapInfo info in result.infos) {
          buffer.writeln("des:${info.description}, ip:${info.ip}, internalPort:${info.internalPort}, externalPort:${info.externalPort}");
        }
        return new CommandResult("portmapped ${buffer.toString()}");
      });
    });
  }
}

class GetLocalIpCommand extends TorrentEngineCommand {
  GetLocalIpCommand() {}

  static String get help => "${name} : get localip command";

  static String get name => "getLocalIp";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new GetLocalIpCommand();
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      return engine.socketBuilder.getNetworkInterfaces().then((List<HetiNetworkInterface> l) {
        StringBuffer buffer = new StringBuffer();
        for (HetiNetworkInterface i in l) {
          buffer.writeln("address:${i.address}, name:${i.name}");
        }
        return new CommandResult(buffer.toString());
      });
    });
  }
}

class TrackerCommand extends TorrentEngineCommand {
  static String get help => "${name} : get localip command";

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
        }
        return new CommandResult(buffer.toString());
      });
    });
  }
}
