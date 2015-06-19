library app;

import 'dart:html' as html;
import 'dart:async';
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimatorrent/hetimatorrent.dart';

class Command {
  
}

class CommandResult {
  toString() {;}
}

class TrackerCommand extends Command {

  Future<CommandResult> execute() {
    Completer<CommandResult> comp = new Completer();
    
    TrackerClient client = new TrackerClient(new HetiSocketBuilderChrome());
    
    return comp.future;
  }
}