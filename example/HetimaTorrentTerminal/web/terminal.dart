import 'dart:core';
import 'dart:html';

//
// ref
// https://www.dartlang.org/samples/terminal/
// '#input-line', '#output', '#cmdline'

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
      
      String cmd = "";
       if (!cmdline.isEmpty) {
         cmdline.trim();
       }
      window.scrollTo(0, window.innerHeight);
    }
  } 
}


