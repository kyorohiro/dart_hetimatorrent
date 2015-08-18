library hetimatorrent.torrent.trackerrserver;

import 'dart:core';
import 'dart:typed_data' as type;
import 'dart:async' as async;
import 'dart:convert';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'trackerurl.dart';
import 'trackerpeermanager.dart';
import '../util/bencode.dart';
import 'trackerresponse.dart';
import 'trackerrequest.dart';
import '../file/torrentfile.dart';

class TrackerServer {
  String address;
  int port;
  HetiHttpServerHelper _server = null;
  bool outputLog = true;
  List<TrackerPeerManager> _peerManagerList = new List();

  String trackerAnnounceAddressForTorrentFile = "";

  bool _isStart = false;
  bool get isStart => _isStart;
  bool _isTorrentfile = true;

  TrackerServer(HetimaSocketBuilder socketBuilder, [bool isTorrentfile = true]) {
    _server = new HetiHttpServerHelper(socketBuilder);
    address = "0.0.0.0";
    port = 6969;
    _isTorrentfile = isTorrentfile;
  }

  List<List<int>> getManagedHash() {
    List<List<int>> ret = [];
    for (TrackerPeerManager m in _peerManagerList) {
      ret.add(new List.from(m.managedInfoHash, growable: false));
    }
    return ret;
  }

  int numOfPeer(List<int> infoHash) {
    for (TrackerPeerManager m in _peerManagerList) {
      if (m.isManagedInfoHash(infoHash)) {
        return m.managedPeerAddress.length;
      }
    }
    return 0;
  }

  void removeInfoHash(List<int> infoHash) {
    List<TrackerPeerManager> tmp = [];
    for (TrackerPeerManager m in _peerManagerList) {
      if (m.isManagedInfoHash(infoHash)) {
        tmp.add(m);
      }
    }
    for (TrackerPeerManager m in tmp) {
      _peerManagerList.remove(m);
    }
  }

  async.Future addTorrentFile(TorrentFile f) {
    return f.createInfoSha1().then((List<int> infoHash) {
      bool isManaged = false;

      for (TrackerPeerManager m in _peerManagerList) {
        if (m.isManagedInfoHash(infoHash)) {
          isManaged = true;
        }
      }

      if (isManaged == true) {
        if (outputLog) {
          print("TrackerServer#add:###non: ${infoHash}");
        }
        return;
      }

      TrackerPeerManager peerManager = new TrackerPeerManager(infoHash, f);
      _peerManagerList.add(peerManager);
      if (outputLog) {
        print("TrackerServer#add:###add: ${infoHash}");
      }
    });
  }

  async.Future addInfoHash(List<int> infoHash) {
    return new async.Future(() {
      bool isManaged = false;

      for (TrackerPeerManager m in _peerManagerList) {
        if (m.isManagedInfoHash(infoHash)) {
          isManaged = true;
        }
      }

      if (isManaged == true) {
        if (outputLog) {
          print("TrackerServer#add:###non: ${infoHash}");
        }
        return;
      }

      // todo
      TrackerPeerManager peerManager = new TrackerPeerManager(infoHash, null);
      _peerManagerList.add(peerManager);
      if (outputLog) {
        print("TrackerServer#add:###add: ${infoHash}");
      }
    });
  }

  async.StreamSubscription res = null;
  async.Future<StartResult> start() {
    if (outputLog) {
      print("TrackerServer#start");
    }
    async.Completer<StartResult> c = new async.Completer();
    _server.basePort = port;
    _server.numOfRetry = 0;

    _server.startServer().then((HetiHttpStartServerResult re) {
      _isStart = true;
      c.complete(new StartResult());
    }).catchError((e) {
      _isStart = false;
      c.completeError(e);
    });
    if (res == null) {
      res = _server.onResponse.listen(onListen);
    }

    return c.future;
  }

  async.Future<StopResult> stop() {
    if (outputLog) {
      print("TrackerServer#stop");
    }
    async.Completer<StopResult> c = new async.Completer();
    _server.stopServer();
    _isStart = false;
    c.complete(new StopResult());
    return c.future;
  }

  void onListen(HetiHttpServerPlusResponseItem item) {
    new async.Future(() {
      String qurey = item.option.replaceFirst(new RegExp(r"^\?"), "");
      Map<String, String> parameter = HttpUrlDecoder.queryMap(qurey);
      print("${qurey}");
      String infoHashAsString = parameter[TrackerUrl.KEY_INFO_HASH];

      if (infoHashAsString == null && (item.path == "/" || item.path == "/index.html") && _isTorrentfile) {
        StringBuffer cont = new StringBuffer();
        for (TrackerPeerManager manager in _peerManagerList) {
          cont.writeln("""<div>[${PercentEncode.encode(manager.managedInfoHash)}]</div>""");
          if (manager.torrentFile != null) {
            cont.writeln("""<div><a href="/your.torrent?infohash=${PercentEncode.encode(manager.managedInfoHash)}&mode=g">  global</a></div>""");
            cont.writeln("""<div><a href="/your.torrent?infohash=${PercentEncode.encode(manager.managedInfoHash)}&mode=l">  local</a></div>""");
          }
        }
        _server.response(item.req, new HetimaBuilderToFile(new ArrayBuilder.fromList(UTF8.encode("<html><head></head><body><div>[managed hash]</div>${cont}</body></html>"))),
            contentType: "text/html");
      } else if (item.path == "/your.torrent" && _isTorrentfile) {
        for (TrackerPeerManager manager in _peerManagerList) {
          if (PercentEncode.encode(manager.managedInfoHash) == parameter["infohash"]) {
            if (manager.torrentFile != null) {
              String addr = trackerAnnounceAddressForTorrentFile;
              if ((addr == null || addr.length == 0) || parameter["mode"] == "l") {
                addr = "http://${address}:${port}/announce";
              }
              manager.torrentFile.announce = addr;
              _server.response(item.req, new HetimaDataMemory(Bencode.encode(manager.torrentFile.mMetadata)));
              return null;
            }
          }
        }
        item.socket.close();
      } else if (item.path == "/redirect" && _isTorrentfile) {
        _server.response(item.req, new HetimaDataMemory([]), statusCode: 301, headerList: {"Location": "/announce?${qurey}"});
      } else if (infoHashAsString != null) {
        return item.socket.getSocketInfo().then((HetimaSocketInfo info) {
          if (outputLog) {
            print("TrackerServer#onListen ${info.peerAddress} ${info.peerPort}");
          }
          List<int> ip = HetiIP.toRawIP(info.peerAddress);

          updateResponse(parameter, ip);
          List<int> cont = createResponse(item.option, HetiIP.toRawIP(info.peerAddress));
          _server.response(item.req, new HetimaDataMemory(cont), contentType: "text/plain");
        });
      } else {
        try {
          item.socket.close();
        } catch (e) {}
      }
    }).catchError((e) {
      try {
        item.socket.close();
      } catch (e) {}
    });
  }

  List<int> createResponse(String query, List<int> ip) {
    if (outputLog) {
      print("TrackerServer#onListen" + query);
    }

    Map<String, String> parameter = HttpUrlDecoder.queryMap(query.replaceFirst(new RegExp(r"^\?"), ""));
    String infoHashAsString = parameter[TrackerUrl.KEY_INFO_HASH];
    String compactAsString = parameter[TrackerUrl.KEY_COMPACT];

    bool isCompact = false;
    if (compactAsString != null && compactAsString == "1") {
      isCompact = true;
    }

    List<int> infoHash = PercentEncode.decode(infoHashAsString);
    TrackerPeerManager manager = find(infoHash);

    if (null == manager) {
      if (outputLog) {
        print("TrackerServer#onListen:###unmanaged");
      }
      // unmanaged torrent data
      Map<String, Object> errorResponse = new Map();
      errorResponse[TrackerResponse.KEY_FAILURE_REASON] = "unmanaged torrent data";
      return Bencode.encode(errorResponse).toList();
    } else {
      // managed torrent data
      type.Uint8List buffer = Bencode.encode(manager.createResponse().createResponse(isCompact, HetiIP.isLocalNetwork(ip)));
      if (outputLog) {
        print("TrackerServer#onListen:###managed" + PercentEncode.encode(buffer.toList()));
      }
      return buffer.toList();
    }
  }

  void updateResponse(Map<String, String> parameter, List<int> ip) {
    if (outputLog) {
      print("TrackerServer#updateResponse ${parameter}");
    }
    try {
      String infoHashAsString = parameter[TrackerUrl.KEY_INFO_HASH];

      List<int> infoHash = PercentEncode.decode(infoHashAsString);
      TrackerPeerManager manager = find(infoHash);

      if (null != manager) {
        // managed torrent data
        manager.update(new TrackerRequest.fromMap(parameter, address, ip));
      }
    } catch (e) {}
  }

  TrackerPeerManager find(List<int> infoHash) {
    for (TrackerPeerManager l in _peerManagerList) {
      if (l.isManagedInfoHash(infoHash)) {
        return l;
      }
    }
    return null;
  }
}

class StopResult {}
class StartResult {}
