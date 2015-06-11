import 'dart:html' as html;
import 'dart:typed_data' as type;
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
  try {
    Object o = Bencode.decode(torrentfileData);
    TorrentFile torrentfile = new TorrentFile.loadTorrentFileBuffer(torrentfileData);
    TrackerUrl url = new TrackerUrl();
    torrentfile.createInfoSha1().then((List<int> id) {
      url.announce = torrentfile.announce;
      url.peerID = PercentEncode.encode(PeerIdCreator.createPeerid("-test-"));
      url.infoHashValue = PercentEncode.encode(id);
      url.event = TrackerUrl.VALUE_EVENT_STARTED;
      url.downloaded = 0;
      url.uploaded = 0;
      url.left = torrentfile.info.files.dataSize;

      result.value = "" + url.toString();
    });
  } catch (E) {
    result.value = "error:" + E.toString();
  }
}
