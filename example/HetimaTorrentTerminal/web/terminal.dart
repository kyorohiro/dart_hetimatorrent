import 'dart:core';
import 'dart:html';
import 'dart:async';
import 'package:hetimatorrent/hetimatorrent.dart';

//
// ref
// https://www.dartlang.org/samples/terminal/
// '#input-line', '#output', '#cmdline'

class Help extends TorrentEngineCommand {
  List<String> args = [];
  Terminal terminal = null;
  Help(Terminal terminal, List<String> args) {
    if (args != null) {
      this.args.addAll(args);
    }
    this.terminal = terminal;
  }

  Future<CommandResult> execute(TorrentEngine engine, {List<String> args: null}) {
    return new Future(() {
      StringBuffer buffer = new StringBuffer();
      for(String key in terminal._commandList.keys) {
        buffer.writeln("[[[${key}]]]");
        buffer.writeln("   ${terminal._commandList[key].help}");
      }
      return new CommandResult(buffer.toString());
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
  Object _subject;
  Terminal(Object subject, String cmdLineId, String outputId, String cmdInputId) {
    this._subject = subject;
    this._cmdLineId = cmdInputId;
    this._outputId = outputId;
    this._cmdInputId = cmdInputId;

    cmdLine = document.querySelector(this._cmdLineId);
    output = document.querySelector(this._outputId);
    input = document.querySelector(this._cmdInputId);

    //cmdLine.onKeyDown.listen(historyHandler);
    cmdLine.onKeyDown.listen(processNewCommand);
    TorrentEngineCommand a(List<String> args) {
      return new Help(this, args);
    }
    ;
    addCommand("help", new TorrentEngineCommandBuilder(a, "help : .. "));
  }

  Map<String, TorrentEngineCommandBuilder> _commandList = {};
  void addCommand(String key, TorrentEngineCommandBuilder builder) {
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

    if (event.keyCode == enterKey) {
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

      List<String> args = cmdline.replaceAll(new RegExp("^[ ]*"), "").split(new RegExp(""" |\t"""));
      if (args.length > 0) {
        if (_commandList.containsKey(args[0])) {
          new Future(() {
            TorrentEngineCommand c = _commandList[args[0]].builder(args.sublist(1));
            return c.execute(_subject, args: args.sublist(1)).then((CommandResult r) {
              output.children.add(new Element.html("<pre>${r.message}</pre>"));
              window.scrollTo(0, window.innerHeight + 30);
            });
          }).catchError((e) {
            output.children.add(new Element.html("<pre>${ _commandList[args[0]].help}</pre>"));
            output.children.add(new Element.html("<pre>${e}</pre>"));
            window.scrollTo(0, window.innerHeight + 30);
          });
        }
      }
    }
    window.scrollTo(0, window.innerHeight + 30);
  }
}
