library hetimatorrent.torrent.trackerrserver;

import 'dart:core';
import 'dart:async';
import 'dart:typed_data' as type;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'trackerurl.dart';
import 'trackerpeermanager.dart';
import '../util/bencode.dart';
import 'trackerresponse.dart';
import 'trackerrequest.dart';

class TorrentClient {
  
  HetiServerSocket _server = null;
  HetiSocketBuilder _builder = null;
  
  TorrentClient(HetiSocketBuilder builder) {
    this._builder = builder;
  }

  Future start() {
    return null;
  }

  Future stop() {
    return null;
  }
}
