import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:args/args.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

Completer c;
main(List<String> args) async {
  String exec = Platform.executable;
  List<String> flags = Platform.executableArguments;
  print("hello ${exec} ${flags} ${args}");

  ArgParser parser = new ArgParser()
    ..addFlag("a", negatable: true, abbr: 'a')
    ..addFlag("b", negatable: false, abbr: 'b')
    ..addOption("c", abbr: 'c');
  ArgResults result = parser.parse(args);
  print("${result.rest} ${result['a']} ${result['b']} ${result['c']}");

  StreamSubscription s = null;
  s = stdin.asBroadcastStream().listen((List<int> v) {
    String line = UTF8.decode(v);
    List<String> lineparts = line.split(new RegExp("[ ]+|\t|\r\n|\r|\n"));
    if (lineparts.length == 0) {
      return;
    }

    print("${lineparts}");
    String action = lineparts[0];
    List<String> args = [];
    if (lineparts.length > 1) {
      args.addAll(lineparts.sublist(1));
    }
    print("${action} ${args}");
    exit(0);
  });
}
