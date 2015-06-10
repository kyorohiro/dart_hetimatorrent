part of app;

class LoadPanel {

  ui.VerticalPanel _loadForSubPanel = new ui.VerticalPanel();
  ui.FileUpload _fileUpload = new ui.FileUpload();
  ui.Html _info = new ui.Html();

  async.StreamController _controllerFileSelect = new async.StreamController.broadcast();
  async.Stream<FileSelectResult> get onSelectFile => _controllerFileSelect.stream;

  void setTorrentInfo(String info) {
    _info.html = info;
  }

  void init() {
    _loadForSubPanel.add(_fileUpload);
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
    _info.text = "drug and drop a torrent file.";
    _loadForSubPanel.add(_info);
  }
}
