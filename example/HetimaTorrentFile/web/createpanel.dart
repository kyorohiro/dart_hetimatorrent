part of app;

class CreatePanel {
  ui.VerticalPanel _createForSubPanel = new ui.VerticalPanel();
  ui.FileUpload _fileUpload = new ui.FileUpload();

  ui.Hyperlink _downloadLink = new ui.Hyperlink();
  ui.TextBox _announceField = new ui.TextBox();
  ui.ListBox _pieceLengthList = new ui.ListBox();
  List<String> _pieceLengthListType = ["16kb", "64kb", "256kb", "1024kb", "4096kb", "16384kb", "65536kb", "262144kb"];
  html.AnchorElement _rawAnchor = new html.AnchorElement();
  html.File _rawFile = null;

  async.StreamController _controllerFileSelect = new async.StreamController.broadcast();
  async.Stream<FileSelectResult> get onSelectFile => _controllerFileSelect.stream;

  CreatePanel() {
    _announceField.text = "http://0.0.0.0:6969/announce";
    for (String l in _pieceLengthListType) {
      _pieceLengthList.addItem(l);
    }
    _pieceLengthList.setItemSelected(0, true);
    _rawAnchor.text = "link";
  }

  int getPieceLength() {
    String vAsString = _pieceLengthList.getValue(_pieceLengthList.getSelectedIndex());
    return int.parse(vAsString.replaceAll("kb", "")) * 1024;
  }

  String getAnnounce() {
    return _announceField.text;
  }

  void setHref(String href) {
    _rawAnchor.href = href;
  }

  void setFile(html.File file) {
    _rawFile = file;
  }

  void init() {
    ui.Anchor anchor;
    ui.Grid grid = new ui.Grid(6, 5);
    grid.addStyleName("cw-FlexTable");
    grid.setWidget(1, 0, new ui.Html("file"));
    grid.setWidget(1, 1, _fileUpload);
    grid.setWidget(2, 0, new ui.Html("announce"));
    grid.setWidget(2, 1, _announceField);
    grid.setWidget(3, 0, new ui.Html("piece length"));
    grid.setWidget(3, 1, _pieceLengthList);
    grid.setWidget(4, 0, new ui.Html("result"));
    grid.setWidget(4, 1, anchor = new ui.Anchor.fromElement(_rawAnchor));
    _createForSubPanel.add(grid);
    dynamic chromeProxy = js.context["chrome"];
    event.ChangeHandler handler = new event.ChangeHandlerAdapter((event.ChangeEvent e) {
      print("##${_fileUpload.name}");
      print("##${_fileUpload.getFilename()}");
      print("##${_fileUpload.title}");
      String path = _fileUpload.getFilename();
      for (html.File f in (_fileUpload.getElement() as html.InputElement).files) {
        hetimacl.HetimaFileBlob file = new hetimacl.HetimaFileBlob(f);
        file.getLength().then((int length) {
          print("###${length}");
          FileSelectResult ff = new FileSelectResult();
          ff.file = file;
          ff.fname = f.name;
          ff.apath = path;
          _controllerFileSelect.add(ff);
        });
      }
    });

    _fileUpload.addChangeHandler(handler);

    anchor.addClickHandler(new event.ClickHandlerAdapter((e) {
      print("click");
      saveFile();
    }));
  }

  void saveFile() {
    String choseFile = "";
    try {
      chrome.fileSystem.chooseEntry(new chrome.ChooseEntryOptions(type: chrome.ChooseEntryType.SAVE_FILE, suggestedName: "a.torrent")).then((chrome.ChooseEntryResult chooseEntryResult) {
        choseFile = chooseEntryResult.entry.toUrl();
        chrome.fileSystem.getWritableEntry(chooseEntryResult.entry).then((chrome.ChromeFileEntry copyTo) {
          hetimacl.HetimaFileBlob copyFrom = new hetimacl.HetimaFileBlob(_rawFile);
          copyFrom.getLength().then((int length) {
            copyFrom.read(0, length).then((hetima.ReadResult readResult) {
              chrome.ArrayBuffer buffer = new chrome.ArrayBuffer.fromBytes(readResult.buffer.toList());
//              copyTo.remove().then((e){
              copyTo.writeBytes(buffer);
//              });
            });
          });
        });
      });
    } catch (e) {
      createDialogBox("failed to copy", new ui.Html("${choseFile}"));
    }
  }
}
