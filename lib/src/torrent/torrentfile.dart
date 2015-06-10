library hetimatorrent.torrent.torrentfile;
import 'dart:typed_data' as data;
import 'dart:convert' as convert;
import 'dart:async' as async;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;
import 'bencode.dart';
import 'hetibencode.dart';
import 'torrentfilehelper.dart';

class TorrentFile {
  static final String KEY_ANNOUNCE = "announce";
  static final String KEY_NAME = "name";
  static final String KEY_INFO = "info";
  static final String KEY_FILES = "files";
  static final String KEY_LENGTH = "length";
  static final String KEY_PIECE_LENGTH = "piece length";
  static final String KEY_PIECES = "pieces";
  static final String KEY_PATH = "path";

  Map mMetadata = {};
  data.ByteBuffer piece = null;
  int piece_length = 0;

  TorrentFile.nullobject() {
    mMetadata = {};
  }

  TorrentFile.loadTorrentFileBuffer(data.Uint8List buffer) {
    mMetadata = Bencode.decode(buffer);
  }

  TorrentFile.torentmap(Map map) {
    mMetadata = map;
  }

  static async.Future<TorrentFile> createTorrentFileFromTorrentFile(hetima.HetimaReader builder) {
    async.Completer<TorrentFile> completer = new async.Completer();
    HetiBencode.decode(new hetima.EasyParser(builder)).then((Object o) {
      completer.complete(new TorrentFile.torentmap(o));
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  String get announce {
    if (mMetadata.containsKey(KEY_ANNOUNCE)) {
      return objectToString(mMetadata[KEY_ANNOUNCE]);
    } else {
      return "";
    }
  }

  void set announce(String v) {
    mMetadata[KEY_ANNOUNCE] = v;
  }

  TorrentFileInfo mInfo = null;
  TorrentFileInfo get info {
    if (mInfo == null) {
      mInfo = new TorrentFileInfo(mMetadata);
    }
    return mInfo;
  }

  async.Future<List<int>> createInfoSha1() {
    TorrentInfoHashCreator creator = new TorrentInfoHashCreator();
    return creator.createInfoHash(this);
  }

}

class TorrentFileInfo {
  Map mInfo = {};
  String get name {
    if (mInfo.containsKey(TorrentFile.KEY_NAME)) {
      return objectToString(mInfo[TorrentFile.KEY_NAME]);
    } else {
      return "";
    }
  }

  void set name(String v) {
    mInfo[TorrentFile.KEY_NAME] = v;
  }

  int get piece_length {
    return mInfo[TorrentFile.KEY_PIECE_LENGTH];
  }
  
  data.Uint8List get pieces {
    return mInfo[TorrentFile.KEY_PIECES];
  }

  TorrentFileFiles get files {
    return new TorrentFileFiles(this);
  }

  TorrentFileInfo(Map metadata) {
    mInfo = metadata[TorrentFile.KEY_INFO];
  }
}

class TorrentFileFiles {
  TorrentFileInfo mInfo = null;
  TorrentFileFiles(TorrentFileInfo info) {
    mInfo = info;
  }

  int get dataSize {
    int ret = 0;
    List<TorrentFileFile> p = path;
    for(TorrentFileFile f in p) {
      ret +=f.length;
    }
    return ret;
  }

  int get numOfFiles {
    if (mInfo.mInfo.containsKey(TorrentFile.KEY_FILES)) {
      return (mInfo.mInfo[TorrentFile.KEY_FILES] as List).length;
    }
    return 1;
  }

  List<TorrentFileFile> get path {
    if (1 == this.numOfFiles) {
      mInfo.name;
      List<TorrentFileFile> ret = new List();
      ret.add(new TorrentFileFile([mInfo.name], mInfo.mInfo[TorrentFile.KEY_LENGTH]));
      return ret;
    } else {
      List<TorrentFileFile> ret = new List();
      List<Map> files = mInfo.mInfo[TorrentFile.KEY_FILES];
      for (Map f in files) {
        ret.add(new TorrentFileFile(f[TorrentFile.KEY_PATH], f[TorrentFile.KEY_LENGTH]));
      }
      return ret;
    }
  }
}

class TorrentFileFile {
  List<String> path = new List();
  int length = 0;
  TorrentFileFile(List p, int l) {
    length = l;
    for (Object o in p) {
      path.add(objectToString(o));
    }
  }
  String get pathAsString {
    StringBuffer buffer = new StringBuffer();
    for (String s in path) {
      buffer.write(s);
    }
    return buffer.toString();
  }
}


String objectToString(Object v) {
  if (v is String) {
    return v;
  } else {
    if(v is data.Uint8List) {
      return convert.UTF8.decode(v.toList());
    } else {
      return convert.UTF8.decode(v);      
    }
  }
}
