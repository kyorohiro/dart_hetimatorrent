library app.mainview.model.seeder;

import 'dart:async';
import 'dart:html' as html;
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class SeederModel {
  TorrentClient client = null;
  
  init(TorrentFile torrentFile, HetimaData seed) {
    TorrentClient.create(new HetiSocketBuilderChrome(),
        PeerIdCreator.createPeerid("seeder"),
        torrentFile, seed);

    
  }
}
