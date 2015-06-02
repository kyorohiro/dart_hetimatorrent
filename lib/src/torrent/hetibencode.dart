library hetimatorrent.torrent.hetibencode;
import 'dart:typed_data' as data;
import 'dart:convert' as convert;
import 'dart:async' as async;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;

class HetiBencode {
  static HetiBdecoder _decoder = new HetiBdecoder();

  static async.Future<Object> decode(hetima.EasyParser parser) {
    return _decoder.decode(parser);
  }

}

class HetiBdecoder {
  static String DIGIT_AS_STRING = "0123456789";
  static List<int> DIGIT = convert.UTF8.encode(DIGIT_AS_STRING);

  async.Future<Object> decode(hetima.EasyParser parser) {
    return decodeBenObject(parser);
  }

  async.Future<Object> decodeBenObject(hetima.EasyParser parser) {
    async.Completer completer = new async.Completer();
    parser.getPeek(1).then((List<int> v) {
      if (0x69 == v[0]) {
        // i
        return decodeNumber(parser).then((int n) {
          completer.complete(n);
        });
      } else if (0x30 <= v[0] && v[0] <= 0x39) {//0-9
        return decodeBytes(parser).then((List<int> v) {
          // todo? byte data is data.Uint8List; 
          completer.complete(new data.Uint8List.fromList(v));
        });
      } else if (0x6c == v[0]) {// l
        return decodeList(parser).then((List<Object> v) {
          completer.complete(v);
        });
      } else if (0x64 == v[0]) {// d
        return decodeDiction(parser).then((Map dict) {
          completer.complete(dict);
        });
      }
      throw new HetiBencodeParseError("benobject");
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<Map> decodeDiction(hetima.EasyParser parser) {
    async.Completer<Map> completer = new async.Completer();
    Map ret = {};
    parser.nextString("d").then((String v) {
      return decodeDictionElements(parser);
    }).then((Map l) {
      ret = l;
    }).then((String v) {
      return parser.nextString("e");
    }).then((e) {
      completer.complete(ret);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<Map> decodeDictionElements(hetima.EasyParser parser) {
    async.Completer<Map> completer = new async.Completer();
    Map ret = new Map();
    async.Future<Object> elem() {
      String key = "";
      return decodeString(parser).then((String v) {
        key = v;
        return decodeBenObject(parser);
      }).then((Object v) {
        ret[key] = v;
        return parser.getPeek(1);
      }).then((List<int> v) {
        if (v[0] == 0x65) { //e
          completer.complete(ret);
        } else {
          elem();
        }
      }).catchError((e){
        completer.completeError(e);
      });
    };
    elem();
    return completer.future;
  }

  async.Future<List<Object>> decodeList(hetima.EasyParser parser) {
    async.Completer<List<Object>> completer = new async.Completer();
    List<Object> ret = [];
    parser.nextString("l").then((String v) {
      return decodeListElement(parser);
    }).then((List<Object> l) {
      ret = l;
    }).then((String v) {
      return parser.nextString("e");
    }).then((e) {
      completer.complete(ret);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<List<Object>> decodeListElement(hetima.EasyParser parser) {
    async.Completer<List<Object>> completer = new async.Completer();
    List<Object> ret = new List();

    async.Future<Object> elem() {
      return decodeBenObject(parser).then((Object v) {
        ret.add(v);
        return parser.getPeek(1).then((List<int> v) {
          if (v.length == 0) {
            completer.completeError(new HetiBencodeParseError("list elm"));
          } else if (v[0] == 0x65) { //e
            completer.complete(ret);
          } else {
            return elem();
          }
        });
      }).catchError((e) {
        completer.completeError(e);
      });
    }
    elem();

    return completer.future;
  }


  async.Future<int> decodeNumber(hetima.EasyParser parser) {
    async.Completer<int> completer = new async.Completer();
    int num = 0;
    parser.nextString("i").then((String v) {
      return parser.nextBytePatternByUnmatch(new hetima.EasyParserIncludeMatcher(DIGIT));
    }).then((List<int> numList) {
      num = intList2int(numList);
      return parser.nextString("e");
    }).then((String v) {
      completer.complete(num);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<String> decodeString(hetima.EasyParser parser) {
    async.Completer<String> completer = new async.Completer();
    decodeBytes(parser).then((List<int> v) {
      try {
        completer.complete(convert.UTF8.decode(v));
      } catch (e) {
        completer.completeError(e);
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<List<int>> decodeBytes(hetima.EasyParser parser) {
    async.Completer<List<int>> completer = new async.Completer();
    int length = 0;
    parser.nextBytePatternByUnmatch(new hetima.EasyParserIncludeMatcher(DIGIT)).then((List<int> lengthList) {
      if (lengthList.length == 0) {
        throw new HetiBencodeParseError("byte:length=0");
      }
      length = intList2int(lengthList);
      return parser.nextString(":");
    }).then((v) {
      return parser.nextBuffer(length);
    }).then((List<int> value) {
      if (value.length == length) {
        completer.complete(value);
      } else {
        throw new HetiBencodeParseError("byte:length:" + value.length.toString() + "==" + length.toString());
      }
    }).catchError((e){
      completer.completeError(e);
    });
    return completer.future;
  }

  static int intList2int(List<int> numList) {
    int num = 0;
    for (int n in numList) {
      num *= 10;
      num += (n - 48);
    }
    return num;
  }
}

class HetiBencodeParseError implements Exception {

  String log = "";
  HetiBencodeParseError(String s) {
    log = s + "#" + super.toString();
  }

  String toString() {
    return log;
  }
}
