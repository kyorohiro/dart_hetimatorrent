library hetimatorrent.torrent.hetibencode;
import 'dart:typed_data' as data;
import 'dart:convert' as convert;
import 'dart:async';
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;

class HetiBencode {
  static HetiBdecoder _decoder = new HetiBdecoder();

  static Future<Object> decode(hetima.EasyParser parser) {
    return _decoder.decode(parser);
  }

}

class HetiBdecoder {
  static String DIGIT_AS_STRING = "0123456789";
  static List<int> DIGIT = convert.UTF8.encode(DIGIT_AS_STRING);

  Future<Object> decode(hetima.EasyParser parser) {
    return decodeBenObject(parser);
  }

  Future<Object> decodeBenObject(hetima.EasyParser parser) async {
    List<int> v = await parser.getPeek(1);
    if (0x69 == v[0]) {// i
      return decodeNumber(parser);
    } else if (0x30 <= v[0] && v[0] <= 0x39) {//0-9
      List<int> vv = await decodeBytes(parser);
      return (vv is data.Uint8List?vv:new data.Uint8List.fromList(vv));
    } else if (0x6c == v[0]) {// l
      return decodeList(parser);
    } else if (0x64 == v[0]) {// d
      return decodeDiction(parser);
    }
    throw new HetiBencodeParseError("benobject");
  }

  Future<Map> decodeDiction(hetima.EasyParser parser) async {
    await parser.nextString("d");
    Map ret = await decodeDictionElements(parser);
    await parser.nextString("e");
    return ret;
  }

  Future<Map> decodeDictionElements(hetima.EasyParser parser) {
    Completer<Map> completer = new Completer();
    Map ret = new Map();
    Future<Object> elem() {
      String key = "";
      return decodeString(parser).then((String v) {
        key = v;
        return decodeBenObject(parser);
      }).then((Object v) {
//        print("##=> ${key} :${v}");//kiyo kiyo
        ret[key] = v;
        return parser.getPeek(1);
      }).then((List<int> v) {
        if (v[0] == 0x65) { //e
          completer.complete(ret);
        } else {
          elem();
        }
      }).catchError((e){
        print("dict error ${parser.index}");
        completer.completeError(e);
      });
    };
    elem();
    return completer.future;
  }

  Future<List<Object>> decodeList(hetima.EasyParser parser) async {
    await parser.nextString("l");
    List<Object> ret = await decodeListElement(parser);
    await parser.nextString("e");
    return ret;
  }

  Future<List<Object>> decodeListElement(hetima.EasyParser parser) {
    Completer<List<Object>> completer = new Completer();
    List<Object> ret = new List();

    Future<Object> elem() {
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


  Future<int> decodeNumber(hetima.EasyParser parser) {
    Completer<int> completer = new Completer();
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

  Future<String> decodeString(hetima.EasyParser parser) {
    Completer<String> completer = new Completer();
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

  Future<List<int>> decodeBytes(hetima.EasyParser parser) {
    Completer<List<int>> completer = new Completer();
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
