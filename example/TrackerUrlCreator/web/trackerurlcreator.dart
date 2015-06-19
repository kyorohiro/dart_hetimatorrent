import 'dart:html' as html;
import 'dart:typed_data' as type;
import 'dart:async' as async;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

void main() {
  html.DivElement drugdtopTag = new html.Element.html("""<div id="drugdrop">drug drop</div>""");
  html.TextAreaElement result = new html.Element.textarea();
  drugdtopTag.onDrop.listen((html.MouseEvent e) {
    e.stopPropagation();
    e.preventDefault();
    for (html.File f in e.dataTransfer.files) {
      read(f, result);
    }
  });
  drugdtopTag.onDragOver.listen((html.MouseEvent e) {
    e.stopPropagation();
    e.preventDefault();
  });

  drugdtopTag.style.width = "100px";
  drugdtopTag.style.height = "100px";
  drugdtopTag.style.backgroundColor = "#800080";

  html.document.body.children.add(drugdtopTag);
  html.document.body.children.add(new html.Element.br());
  html.document.body.children.add(result);
  html.document.body.children.add(new html.Element.br());
}

void read(html.File f, html.TextAreaElement result) {
  html.FileReader reader = new html.FileReader();
  reader.readAsArrayBuffer(f);
  reader.onLoadEnd.listen((html.ProgressEvent e) {
    print("==" + reader.result.runtimeType.toString());
    createTrackerUrl(reader.result, result);
  });
}

void createTrackerUrl(type.Uint8List torrentfileData, html.TextAreaElement result) {
  new async.Future(() {
    Object o = Bencode.decode(torrentfileData);
    TorrentFile torrentfile = new TorrentFile.loadTorrentFileBuffer(torrentfileData);
    return TrackerUrl.createTrackerUrlFromTorrentFile(torrentfile, PeerIdCreator.createPeerid("-test-")).then((TrackerUrl url) {
      result.value = "" + url.toString();
    });
  }).catchError((e){
    result.value = "error:" + e.toString();
  });

}
