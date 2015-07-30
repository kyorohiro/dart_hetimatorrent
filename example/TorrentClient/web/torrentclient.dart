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
  TorrentEngine engine;
  List<File> selectedFile = (querySelector("#inputFile") as InputElement).files;

  bool isStop = false;
  return TorrentFile.createFromTorrentFile(new HetimaFileToBuilder(new HetimaDataBlob(selectedFile[0]))).then((TorrentFile torrentFile) {
    return TorrentEngine.createTorrentEngine(new HetiSocketBuilderChrome(), torrentFile, new HetimaDataFS("save.dat")).then((TorrentEngine engine) {
      engine.start(usePortMap: true);
      engine.onProgress.listen((TorrentEngineProgress progress) {
        print("${progress.toString()}");
        if (progress.downloadSize >= progress.fileSize && isStop == false) {
          isStop = true;
          new Future.delayed(new Duration(minutes: 5)).then((_) {
            engine.stop().catchError((e) {});
          });
        }
      });
    });
  });
}
