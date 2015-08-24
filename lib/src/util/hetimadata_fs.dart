library hetimacore_cl.impl;

import 'dart:typed_data' as data;
import 'dart:async' as async;
import 'dart:core';
import 'dart:html' as html;
import 'package:hetimacore/hetimacore.dart';

class HetimaDataFSDebugBuilder extends HetimaDataBuilder {
  async.Future<HetimaData> createHetimaData(String path) {
    async.Completer<HetimaData> co = new async.Completer();
    co.complete(new HetimaDataFSDebug(path));
    return co.future;
  }
}

class HetimaDataFSDebug extends HetimaData {
  String fileName = "";
  html.FileEntry _fileEntry = null;

  bool get writable => true;
  bool get readable => true;

  bool _erace = false;
  bool _persistent = false;
  HetimaDataFSDebug(String name,{erace:false,persistent:false}) {
    fileName = name;
    _erace = erace;
    _persistent = persistent;
  }

  HetimaDataFSDebug.fromFile(html.FileEntry fileEntry) {
    this._fileEntry = fileEntry;
    fileName = fileEntry.name;
  }

  async.Future<html.Entry> getEntry() {
    return init();
  }

  async.Future<html.Entry> init() {
    async.Completer<html.Entry> completer = new async.Completer();
    if (_fileEntry != null) {
      completer.complete(_fileEntry);
      return completer.future;
    }
    html.window.requestFileSystem(1024,persistent: _persistent).then((html.FileSystem e) {
      e.root.createFile(fileName).then((html.Entry e) {
        _fileEntry = (e as html.FileEntry);
        if(_erace == true) {
          return truncate(0).then((_){
            completer.complete(_fileEntry);            
          });
        } else {
          completer.complete(_fileEntry);
        }
      }).catchError((es) {
        completer.complete(null);
      });
    });
    return completer.future;
  }

  async.Future<int> getLength() {
    async.Completer<int> completer = new async.Completer();
    init().then((e) {
      _fileEntry.file().then((html.File f) {
        completer.complete(f.size);
      });
    });
    return completer.future;
  }

  async.Future<WriteResult> write(Object buffer, int start) {
    if (buffer is List<int> && !(buffer is data.Uint8List)) {
      buffer = new data.Uint8List.fromList(buffer);
    }

    async.Completer<WriteResult> completer = new async.Completer();
    init().then((e) {
      _fileEntry.createWriter().then((html.FileWriter writer) {
        writer.onWrite.listen((html.ProgressEvent e) {
          writer.abort();
          completer.complete(new WriteResult());
        });
        writer.onError.listen((e){
          completer.completeError({});
        });
        return getLength().then((int len) {
          data.Uint8List dummy = null;
          if (len < start) {
            //print("########---< new List ${start-len}");
            dummy =  new data.Uint8List.fromList(new List.filled(start-len, 0));
            writer.seek(len);
          } else {
            //print("########--- new List 0");
            dummy =  new data.Uint8List.fromList([]);            
            writer.seek(start);
          }
          writer.write(new html.Blob([dummy,buffer]));
        });
      });
    });
    return completer.future;
  }

  async.Future<int> truncate(int fileSize) {
    async.Completer<int> completer = new async.Completer();
    init().then((e) {
      return _fileEntry.createWriter();
    }).then((html.FileWriter writer) {
      writer.truncate(fileSize);
      completer.complete(fileSize);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<ReadResult> read(int offset, int length, {List<int> tmp:null}) {
    async.Completer<ReadResult> c_ompleter = new async.Completer();
    init().then((e) {
      html.FileReader reader = new html.FileReader();
      _fileEntry.file().then((html.File f) {
        reader.onLoadEnd.listen((html.ProgressEvent e) {
          c_ompleter.complete(new ReadResult(ReadResult.OK, reader.result));
        });
        reader.readAsArrayBuffer(f.slice(offset, offset + length));
      });
    });
    return c_ompleter.future;
  }

  void beToReadOnly() {}
  
  static async.Future<List<String>> getFiles({persistent:false}) {
    return html.window.requestFileSystem(1024,persistent: persistent).then((html.FileSystem e) {
      return e.root.createReader().readEntries().then((List<html.Entry> files) {
        List<String> ret = [];
        for(html.Entry e in files) {
          if(e.isFile) {
           ret.add(e.name);
          }
        }
        return ret;
      });
    });
  }
  
  static async.Future removeFile(String filename, {persistent:false}) {
    return html.window.requestFileSystem(1024,persistent: persistent).then((html.FileSystem e) {
      return e.root.getFile(filename).then((html.Entry e) {
        return e.remove();
      });
    });
  }
}
