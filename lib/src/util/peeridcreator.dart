library hetimatorrent.util.peeridcreator;
import 'dart:math' as math;
import 'dart:core';

class PeerIdCreator {
  static math.Random _random = new math.Random(new DateTime.now().millisecond);
  static List<int> createPeerid(String id) {
    List<int> output = new List<int>(20);
    for (int i = 0; i < 20; i++) {
      output[i] = _random.nextInt(0xFF);
    }
    List<int> idAsCode = id.codeUnits;
    for (int i = 0; i < 5 && i < idAsCode.length; i++) {
      output[i + 1] = idAsCode[i];
    }
    return output;
  }
}