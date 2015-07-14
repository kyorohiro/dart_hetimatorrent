library hetimatorrent.torrent.torrentfile;

import 'dart:typed_data' as data;
import 'dart:convert' as convert;
import 'dart:async' as async;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;
import '../util/bencode.dart';
import '../util/hetibencode.dart';
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

  static const int PIECE_LENGTH_16 = 1024 * 16;
  static const int PIECE_LENGTH_32 = PIECE_LENGTH_16 * 2;
  static const int PIECE_LENGTH_64 = PIECE_LENGTH_32 * 2;
  static const int PIECE_LENGTH_128 = PIECE_LENGTH_64 * 2;
  static const int PIECE_LENGTH_256 = PIECE_LENGTH_128 * 2;
  static const int PIECE_LENGTH_512 = PIECE_LENGTH_256 * 2;
  static const int PIECE_LENGTH_1024 = PIECE_LENGTH_512 * 2;
  static const int PIECE_LENGTH_2048 = PIECE_LENGTH_1024 * 2;

  static int getRecommendPieceLength(int fileSize) {
    int pieceSize = fileSize ~/ 1024 + 1;
    int size = PIECE_LENGTH_128;
    for (int i = 0; i < 4; i++) {
      if (pieceSize <= size * 2) {
        return size;
      }
      size *= 2;
    }
    return PIECE_LENGTH_1024;
  }

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
  Map _mInfo = {};
  String get name {
    if (_mInfo.containsKey(TorrentFile.KEY_NAME)) {
      return objectToString(_mInfo[TorrentFile.KEY_NAME]);
    } else {
      return "";
    }
  }

  void set name(String v) {
    _mInfo[TorrentFile.KEY_NAME] = v;
  }

  int get piece_length {
    return _mInfo[TorrentFile.KEY_PIECE_LENGTH];
  }

  data.Uint8List get pieces {
    return _mInfo[TorrentFile.KEY_PIECES];
  }

  TorrentFileFiles get files {
    return new TorrentFileFiles(this);
  }

  TorrentFileInfo(Map metadata) {
    _mInfo = metadata[TorrentFile.KEY_INFO];
  }
}

class TorrentFileFiles {
  TorrentFileInfo _info = null;
  TorrentFileFiles(TorrentFileInfo info) {
    _info = info;
  }

  int get dataSize {
    int ret = 0;
    List<TorrentFileFile> p = files;
    for (TorrentFileFile f in p) {
      ret += f.fileSize;
    }
    return ret;
  }

  int get numOfFiles {
    if (_info._mInfo.containsKey(TorrentFile.KEY_FILES)) {
      return (_info._mInfo[TorrentFile.KEY_FILES] as List).length;
    }
    return 1;
  }

  List<TorrentFileFile> get files {
    if (1 == this.numOfFiles) {
      _info.name;
      List<TorrentFileFile> ret = new List();
      ret.add(new TorrentFileFile([_info.name], _info._mInfo[TorrentFile.KEY_LENGTH], 0));
      return ret;
    } else {
      List<TorrentFileFile> ret = new List();
      List<Map> files = _info._mInfo[TorrentFile.KEY_FILES];
      int index = 0;
      for (Map f in files) {
        ret.add(new TorrentFileFile(f[TorrentFile.KEY_PATH], f[TorrentFile.KEY_LENGTH], index));
        index += f[TorrentFile.KEY_LENGTH];
      }
      return ret;
    }
  }
}

class TorrentFileFile {
  List<String> path = new List();
  int _index = 0;
  int get index => _index;
  int _fileSize = 0;
  int get fileSize => _fileSize;
  TorrentFileFile(List p, int l, int index) {
    _fileSize = l;
    for (Object o in p) {
      path.add(objectToString(o));
    }
    _index = index;
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
    if (v is data.Uint8List) {
      return convert.UTF8.decode(v.toList());
    } else {
      return convert.UTF8.decode(v);
    }
  }
}
