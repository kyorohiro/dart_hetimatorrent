library hetimatorrent.extra.torrentengine.torrent;

import 'dart:async';
import 'dart:typed_data';
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimatorrent/hetimatorrent.dart';
import '../client/torrentclient.dart';
import '../tracker/trackerclient.dart';
import 'torrentengineai.dart';
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
      {haveAllData: false, int localPort: 18085, int globalPort: 18085, List<int> bitfield: null, useDht: false}) async {
    TorrentEngineTorrent engineTorrent = new TorrentEngineTorrent._e();
    TrackerClient trackerClient = await TrackerClient.createTrackerClient(engine.builder, torrentfile);
    engineTorrent._trackerClient = trackerClient;
    engineTorrent.ai = new TorrentEngineAI(trackerClient, engine.dhtClient, useDht);

    //
    List<int> reserved = [0, 0, 0, 0, 0, 0, 0, 0];
    if (useDht == true) {
      reserved = [0, 0, 0, 0, 0, 0, 0, 0x01];
    }

    engineTorrent._infoHash.addAll(trackerClient.infoHash);
    engineTorrent._torrentClient = new TorrentClient(
        engine.builder, trackerClient.peerId, trackerClient.infoHash, torrentfile.info.pieces, 
        torrentfile.info.piece_length, torrentfile.info.files.dataSize, downloadedData,
        ai: engineTorrent.ai, haveAllData: haveAllData, bitfield: bitfield, reserved: reserved);
    engineTorrent._torrentFile = torrentfile;
    engineTorrent._downloadedData = downloadedData;

    return engineTorrent;
  }

  Future startTorrent(TorrentEngine engine) async {
    await createBaseFile();
    return await ai.start(engine.torrentClientManager, _torrentClient);
  }

  Future stopTorrent() {
    return ai.stop();
  }
  
  Future addTorrentClient(String ip, int port) async {
    _torrentClient.putTorrentPeerInfoFromTracker(ip, port);
  }

  Future createBaseFile() async {
    int length = _torrentFile.info.files.dataSize;
    Uint8List buffer = new Uint8List.fromList(new List.filled(16 * 1024 * 1024, 0));
    int start = await _downloadedData.getLength();
    int end = start;
    int retry = 0;
    while (start < length) {
      end = (start + buffer.length > length ? length : start + buffer.length);
      try {
        await _downloadedData.write(buffer, start);
        start = end;
        retry = 0;
      } catch (e) {
        retry++;
        if (retry > 5) {
          throw e;
        }
        //
        // chrome file api need to wait , when write into file with giga bytes data.
        await new Future.delayed(new Duration(seconds: 1));
      }
    }
  }
}
