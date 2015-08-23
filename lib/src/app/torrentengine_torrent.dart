library hetimatorrent.extra.torrentengine;

import 'dart:async';
import 'dart:typed_data';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import 'torrentengineai.dart';
import 'torrentengineai_protmap.dart';
import 'torrentengine.dart';

class TorrentEngineTorrent {
  TorrentClient _torrentClient = null;
  TrackerClient _trackerClient = null;
  TorrentClient get torrentClient => _torrentClient;
  TrackerClient get trackerClient => _trackerClient;
  TorrentFile _torrentFile = null;
  TorrentFile get torrentFile => _torrentFile;
  TorrentEngineAI ai = null;
  HetimaData _downloadedData = null;
  Stream<TorrentEngineProgress> get onProgress => ai.onProgress;
  TorrentEngineTorrent._e() {}
  List<int> _infoHash = [];
  List<int> get infoHash => new List.from(_infoHash);
  List<int> get rawinfoHash => _infoHash;

  static Future<TorrentEngineTorrent> createEngioneTorrent(TorrentEngine engine, TorrentFile torrentfile, HetimaData downloadedData,
      {haveAllData: false, int localPort: 18085, int globalPort: 18085, List<int> bitfield: null, useDht: false}) {
    TorrentEngineTorrent engineTorrent = new TorrentEngineTorrent._e();
    return TrackerClient.createTrackerClient(engine.builder, torrentfile).then((TrackerClient trackerClient) {
      engineTorrent._trackerClient = trackerClient;
      engineTorrent.ai = new TorrentEngineAI(trackerClient, engine.dhtClient, useDht);

      //
      List<int> reserved = [0, 0, 0, 0, 0, 0, 0, 0];
      if (useDht == true) {
        reserved = [0, 0, 0, 0, 0, 0, 0, 0x01];
      }

      engineTorrent._infoHash.addAll(trackerClient.infoHash);
      engineTorrent._torrentClient = new TorrentClient(
          engine.builder, trackerClient.peerId, trackerClient.infoHash, torrentfile.info.pieces, torrentfile.info.piece_length, torrentfile.info.files.dataSize, downloadedData,
          ai: engineTorrent.ai, haveAllData: haveAllData, bitfield: bitfield, reserved: reserved);
      engineTorrent._torrentFile = torrentfile;
      engineTorrent._downloadedData = downloadedData;

      return engineTorrent;
    });
  }

  Future startTorrent(TorrentEngine engine) {
    return init().then((_) {
      return ai.start(engine.torrentClientManager, _torrentClient);
    });
  }

  Future stopTorrent() {
    return ai.stop();
  }

  Future init() async {
    int length = _torrentFile.info.files.dataSize;
    Uint8List buffer = new Uint8List.fromList(new List.filled(16 * 1024 * 1024, 0));
    int start = await _downloadedData.getLength();
    int end = start;
    int retry = 0;
    Future write() async {
      if (start >= length) {
        return {};
      }
      end = (start + buffer.length > length?length:start + buffer.length);

      return _downloadedData.write(buffer, start).then((_) {
        start = end;
        retry = 0;
        return write();
      }).catchError((_) {
        retry++;
        if (retry > 5) {
          throw _;
        }
        return new Future.delayed(new Duration(seconds: 1)).then((_) {
          return write();
        });
      });
    }
    return write();
  }
}
