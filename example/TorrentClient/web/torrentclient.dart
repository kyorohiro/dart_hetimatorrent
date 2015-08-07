import 'dart:html';
import 'dart:async';

import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimacore/hetimacore.dart';

void main() {
  querySelector("#inputFile").onChange.listen(startDownload);
}

Future startDownload(MouseEvent event) {
  List<File> selectedFile = (querySelector("#inputFile") as InputElement).files;

  bool isStop = false;
  return TorrentFile.createFromTorrentFile(new HetimaFileToBuilder(new HetimaDataBlob(selectedFile[0]))).then((TorrentFile torrentFile) {
    TorrentEngine engine = new TorrentEngine(new HetiSocketBuilderChrome(), useUpnp: true);
    engine.addTorrent(torrentFile, new HetimaDataFS("save.dat")).then((TorrentEngineTorrent enginetorrent) {
      engine.start();
      enginetorrent.onProgress.listen((TorrentEngineProgress progress) {
        print("${progress.toString()}");
        if (progress.downloadSize >= progress.fileSize && isStop == false) {
          isStop = true;
          new Future.delayed(new Duration(minutes: 5)).then((_) {
            engine.stop().catchError((e) {});
          });
        }
      });
      enginetorrent.startTorrent(engine);
    });
  });
}
