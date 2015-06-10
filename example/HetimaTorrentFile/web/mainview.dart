part of app;

class MainView {

  static const int TAB_LOAD = 0;
  static const int TAB_CREATE = 1;

  ui.VerticalPanel _mainPanel = new ui.VerticalPanel();
  ui.VerticalPanel _subPanel = new ui.VerticalPanel();

  async.StreamController _controllerTab = new async.StreamController.broadcast();
  async.Stream<int> get onSelectTab => _controllerTab.stream;

  ui.VerticalPanel mainForSubPanel = new ui.VerticalPanel();
  ui.FileUpload _fileUpload = new ui.FileUpload();

  LoadPanel _mLoadPanel = new LoadPanel();
  CreatePanel _mCreatePanel = new CreatePanel();
  async.Stream<FileSelectResult> get onSelectTorrentFile => _mLoadPanel.onSelectFile;
  async.Stream<FileSelectResult> get onSelectRawFile => _mCreatePanel.onSelectFile;

  int get pieceLength => _mCreatePanel.getPieceLength(); 
  String get announce => _mCreatePanel.getAnnounce();
  void set downloadFile(html.File file) => _mCreatePanel.setFile(file);
  void set downloadHref(String href) => _mCreatePanel.setHref(href);
  void set torrentInfo(String info) => _mLoadPanel.setTorrentInfo(info);

  void intialize() {
    _mLoadPanel.init();
    _mCreatePanel.init();

    initTab();

    ui.RootPanel.get().add(_mainPanel);
    updateLoadPanel();
  }


  void updateLoadPanel() {
    _subPanel.clear();
    _subPanel.add(_mLoadPanel._loadForSubPanel);
  }

  void updateCreatePanel() {
    _subPanel.clear();
    _subPanel.add(_mCreatePanel._createForSubPanel);
  }

  void initTab() {
    ui.TabBar bar = new ui.TabBar();
    bar.addTabText("load");
    bar.addTabText("create");
    bar.selectTab(0);
    _mainPanel.add(bar);
    _mainPanel.add(_subPanel);

    bar.addSelectionHandler(new event.SelectionHandlerAdapter((event.SelectionEvent evt) {
      int selectedTabIndx = evt.getSelectedItem();
      if (selectedTabIndx == 0) {
        updateLoadPanel();
        _controllerTab.add(TAB_LOAD);
      } else if (selectedTabIndx == 1) {
        updateCreatePanel();
      }
    }));
  }
}


class FileSelectResult {
  String apath;
  String fname;
  hetima.HetimaData file;
}

/**
 * ui.DialogBox dialogBox = createDialogBox(String title, ui.Widget body)
 * dialogBox.setGlassEnabled(false);
 * dialogBox.show();
 * dialogBox.center();
 */
ui.DialogBox createDialogBox(String title, ui.Widget body) {
  ui.DialogBox dialogBox = new ui.DialogBox();
  dialogBox.text = title;

  // Create a table to layout the content
  ui.VerticalPanel dialogContents = new ui.VerticalPanel();
  dialogContents.spacing = 4;
  dialogBox.setWidget(dialogContents);

  // Add some text to the top of the dialog
  dialogContents.add(body);
  dialogContents.setWidgetCellHorizontalAlignment(body, i18n.HasHorizontalAlignment.ALIGN_CENTER);

  // Add a close button at the bottom of the dialog
  ui.Button closeButton = new ui.Button("Close", new event.ClickHandlerAdapter((event.ClickEvent evt) {
    dialogBox.hide();
  }));
  dialogContents.add(closeButton);
  if (i18n.LocaleInfo.getCurrentLocale().isRTL()) {
    dialogContents.setWidgetCellHorizontalAlignment(closeButton, i18n.HasHorizontalAlignment.ALIGN_LEFT);
  } else {
    dialogContents.setWidgetCellHorizontalAlignment(closeButton, i18n.HasHorizontalAlignment.ALIGN_RIGHT);
  }

  // Return the dialog box
  return dialogBox;
}

