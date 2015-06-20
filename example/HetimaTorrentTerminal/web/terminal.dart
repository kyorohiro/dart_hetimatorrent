import 'dart:core';
import 'dart:html';
import 'dart:async';
import 'package:hetimatorrent/hetimatorrent.dart';

//
// ref
// https://www.dartlang.org/samples/terminal/
// '#input-line', '#output', '#cmdline'

class Echo extends TorrentEngineCommand {
  List<String> args = [];
  Echo(List<String> args) {
    if(args != null) {
     this.args.addAll(args);
    }
  }

  Future<CommandResult> execute(TorrentEngine engine,{List<String> args:null}) {
    return new Future((){
      print("echo ${args}");
      return new CommandResult("echo ${args}");
    });
  }
}

class Terminal {

  String _cmdLineId = "";
  String _outputId = "";
  String _cmdInputId = "";

  Element cmdLine;
  Element output;
  InputElement input;

  Terminal(String cmdLineId, String outputId, String cmdInputId) {
    this._cmdLineId = cmdInputId;
    this._outputId = outputId;
    this._cmdInputId = cmdInputId;

    cmdLine = document.querySelector(this._cmdLineId);
    output = document.querySelector(this._outputId);
    input = document.querySelector(this._cmdInputId);
    
    //cmdLine.onKeyDown.listen(historyHandler);
    cmdLine.onKeyDown.listen(processNewCommand);
    TorrentEngineCommand a(List<String> args) {
      return new Echo(args);
    };
    addCommand("echo", a);
  }

  Map<String, Function> _commandList = {};
  void addCommand(String key, TorrentEngineCommand builder(List<String> args)) {
    _commandList[key] = builder;
  }

  void processNewCommand(KeyboardEvent event) {
    print("processNewCommand: --");
    print("--ctrlKey = ${event.ctrlKey}");
    print("--keyCoede = ${event.keyCode}");
    print("--metaKey = ${event.metaKey}");
    print("--altKey ${event.altKey}");
    print("--shiftkey ${event.shiftKey}");
    print("--charCode ${event.charCode}");
    int enterKey = 13;
    int tabKey = 9;

    
    if(event.keyCode == enterKey) {
      DivElement line = input.parent.clone(true);
      line.attributes.remove('id');
      line.classes.add('line');
      InputElement cmdInput = line.querySelector(_cmdInputId);
      cmdInput.attributes.remove('id');
      cmdInput.autofocus = false;
      cmdInput.readOnly = true;
      output.children.add(line);

      String cmdline = input.value;
      input.value = ""; // clear input
      
      List<String> args = cmdline.split(new RegExp(""" |\t"""));
      if(args.length > 0) {
        if(_commandList.containsKey(args[0])){
          TorrentEngineCommand c = _commandList[args[0]](args.sublist(1));
          c.execute(null,args:args.sublist(1)).then((CommandResult r) {
            output.children.add(new Element.html("<div>${r.message}</div>"));
          });
        }
      }
      window.scrollTo(0, window.innerHeight);
    }
  } 
}


