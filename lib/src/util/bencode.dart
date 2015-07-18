library hetimatorrent.torrent.bencode;
import 'dart:typed_data' as data;
import 'dart:convert' as convert;
import 'dart:core';
import 'package:hetimacore/hetimacore.dart' as hetima;

class Bencode {
  static Bencoder _encoder = new Bencoder();
  static Bdecoder _decoder = new Bdecoder();

  static data.Uint8List encode(Object obj) {
    return _encoder.enode(obj);
  }

  static Object decode(data.Uint8List buffer) {
    return _decoder.decode(buffer);
  }

  static String toText(Object oo, String key, String def) {
    try {
      if (!(oo is Map)) {
        return def;
      }
      Map p = oo as Map;
      if (!p.containsKey(key)) {
        return def;
      }
      if (!(p[key] is data.Uint8List)) {
        return def;
      }
      return convert.UTF8.decode((p[key] as data.Uint8List).toList());
    } catch (e) {
      return def;
    }
  }

  static num toNum(Object oo, String key, num def) {
    try {
      if (!(oo is Map)) {
        return def;
      }
      Map p = oo as Map;
      if (!p.containsKey(key)) {
        return def;
      }
      if (!(p[key] is num)) {
        return def;
      }
      return p[key];
    } catch (e) {
      return def;
    }
  }

  static List toList(Object oo, String key) {
    try {
      if (!(oo is Map)) {
        return [];
      }
      Map p = oo as Map;
      if (!p.containsKey(key)) {
        return [];
      }
      if (!(p[key] is List)) {
        return [];
      }
      return p[key];
    } catch (e) {
      return [];
    }
  }

  static Map toMap(Object oo, String key) {
    try {
      if (!(oo is Map)) {
        return {};
      }
      Map p = oo as Map;
      if (!p.containsKey(key)) {
        return {};
      }
      if (!(p[key] is Map)) {
        return {};
      }
      return p[key];
    } catch (e) {
      return {};
    }
  }
}

class Bdecoder {
  int index;
  Object decode(data.Uint8List buffer) {
    index = 0;
    return decodeBenObject(buffer);
  }

  Object decodeBenObject(data.Uint8List buffer) {
    if (0x30 <= buffer[index] && buffer[index] <= 0x39) {//0-9
      return decodeBytes(buffer);
    } else if (0x69 == buffer[index]) {// i
      return decodeNumber(buffer);
    } else if (0x6c == buffer[index]) {// l
      return decodeList(buffer);
    } else if (0x64 == buffer[index]) {// d
      return decodeDiction(buffer);
    }
    throw new BencodeParseError("benobject", buffer, index);
  }

  Map decodeDiction(data.Uint8List buffer) {
    Map ret = new Map();
    if (buffer[index++] != 0x64) {
      throw new BencodeParseError("bendiction", buffer, index);
    }

    ret = decodeDictionElements(buffer);

    if (buffer[index++] != 0x65) {
      throw new BencodeParseError("bendiction", buffer, index);
    }
    return ret;
  }

  Map decodeDictionElements(data.Uint8List buffer) {
    Map ret = new Map();
    while (index < buffer.length && buffer[index] != 0x65) {
      data.Uint8List keyAsList = decodeBenObject(buffer);
      String key = convert.UTF8.decode(keyAsList.toList());
      ret[key] = decodeBenObject(buffer);
    }
    return ret;
  }

  List decodeList(data.Uint8List buffer) {
    List ret = new List();
    if (buffer[index++] != 0x6c) {
      throw new BencodeParseError("benlist", buffer, index);
    }
    ret = decodeListElemets(buffer);
    if (buffer[index++] != 0x65) {
      throw new BencodeParseError("benlist", buffer, index);
    }
    return ret;
  }

  List decodeListElemets(data.Uint8List buffer) {
    List ret = new List();
    while (index < buffer.length && buffer[index] != 0x65) {
      ret.add(decodeBenObject(buffer));
    }
    return ret;
  }

  num decodeNumber(data.Uint8List buffer) {
    if (buffer[index++] != 0x69) {
      throw new BencodeParseError("bennumber", buffer, index);
    }
    int returnValue = 0;
    while (index < buffer.length && buffer[index] != 0x65) {
      if (!(0x30 <= buffer[index] && buffer[index] <= 0x39)) {
        throw new BencodeParseError("bennumber", buffer, index);
      }
      returnValue = returnValue * 10 + (buffer[index++] - 0x30);
    }
    if (buffer[index++] != 0x65) {
      throw new BencodeParseError("bennumber", buffer, index);
    }
    return returnValue;
  }

  data.Uint8List decodeBytes(data.Uint8List buffer) {
    int length = 0;
    while (index < buffer.length && buffer[index] != 0x3a) {
      if (!(0x30 <= buffer[index] && buffer[index] <= 0x39)) {
        throw new BencodeParseError("benstring", buffer, index);
      }
      length = length * 10 + (buffer[index++] - 0x30);
    }
    if (buffer[index++] != 0x3a) {
      throw new BencodeParseError("benstring", buffer, index);
    }
    data.Uint8List ret = new data.Uint8List.fromList(buffer.sublist(index, index + length));
    index += length;
    return ret;
  }
}

class Bencoder {
  hetima.ArrayBuilder builder = new hetima.ArrayBuilder();


  data.Uint8List enode(Object obj) {
    builder.clear();
    encodeObject(obj);
    return builder.toUint8List();
  }

  void encodeString(String obj) {
    List<int> buffer = convert.UTF8.encode(obj);
    builder.appendString("" + buffer.length.toString() + ":" + obj);
  }

  void encodeUInt8List(data.Uint8List buffer) {
    builder.appendString("" + buffer.lengthInBytes.toString() + ":");
    builder.appendUint8List(buffer, 0, buffer.length);
  }

  void encodeNumber(num num) {
    builder.appendString("i" + num.toString() + "e");
  }

  void encodeDictionary(Map obj) {
    Iterable<String> keys = obj.keys;
    builder.appendString("d");
    for (var key in keys) {
      encodeString(key);
      encodeObject(obj[key]);
   //   print("##-> ${key} : ${obj[key]}");//kiyo kiyo
    }
    builder.appendString("e");
  }

  void encodeList(List list) {
    builder.appendString("l");
    for (int i = 0; i < list.length; i++) {
      encodeObject(list[i]);
    }
    builder.appendString("e");
  }

  void encodeObject(Object obj) {
    if (obj is num) {
      encodeNumber(obj);
    } else if (identical(obj, true)) {
      encodeString("true");
    } else if (identical(obj, false)) {
      encodeString("false");
    } else if (obj == null) {
      encodeString("null");
    } else if (obj is String) {
      encodeString(obj);
    } else if (obj is data.ByteBuffer) {
      encodeUInt8List(new data.Uint8List.view(obj));
    } else if (obj is data.Uint8List) {
      encodeUInt8List(obj);
    } else if (obj is List) {
      encodeList(obj);
    } else if (obj is Map) {
      encodeDictionary(obj);
    }
  }
}

class BencodeParseError implements Exception {

  String log = "";
  BencodeParseError(String s, data.Uint8List buffer, int index) {
    log = s + "#" + buffer.toList().toString() + "index=" + index.toString() + ":" + super.toString();
  }

  String toString() {
    return log;
  }
}
