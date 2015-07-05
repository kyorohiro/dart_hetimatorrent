library hetimatorrent.extra.upnpcommand;

import 'dart:async';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import 'torrentengine.dart';



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
      engine.upnpPortMapClient.localAddress = localIp;
      engine.upnpPortMapClient.basePort = globalPort;
      engine.upnpPortMapClient.localPort = localPort;
      engine.upnpPortMapClient.numOfRetry = 0;
      return engine.upnpPortMapClient.startPortMap().then((StartPortMapResult result) {
        return new CommandResult("portmapped ${result.hashCode}");
      });
    });
  }
}

class StopUpnpPortMapCommand extends TorrentEngineCommand {

  StopUpnpPortMapCommand() {
  }

  static String get help => "${name}: request port map commaand";
  static String get name => "stopPortMap";

  static TorrentEngineCommandBuilder builder() {
    TorrentEngineCommand builder(List<String> list) {
      return new StopUpnpPortMapCommand();
    }
    return new TorrentEngineCommandBuilder(builder, help);
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      return engine.upnpPortMapClient.deletePortMapFromAppIdDesc().then((DeleteAllPortMapResult result) {
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
      return engine.upnpPortMapClient.getPortMapInfo().then((GetPortMapInfoResult result) {
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

