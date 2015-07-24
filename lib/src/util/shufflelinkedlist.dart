library hetimatorrent.util.shufflelinkedlist;

import 'dart:math' as math;
import 'dart:core';

class ShuffleLinkedList<X> {
  List<X> _sequential = new List();
  List<X> _shuffled = new List();

  List<X> get sequential => new List.from(_sequential);

  int _max = 0;
  int get max => _max;

  ShuffleLinkedList([int max=0]) {
    _max = max;
  }

  X addLast(X value) {
    // contain
    {
      X xx = null;
      for (X x in _sequential) {
        if (x == value) {
          xx = x;
          break;
        }
      }
      if (xx != null) {
        _sequential.remove(xx);
        _sequential.add(xx);
        return xx;
      }
    }
    _sequential.add(value);
    _shuffled.add(value);
    if(_max != 0 && length > _max) {
      removeHead();
    }
    return value;
  }

  //
  // remove from head. if full. 
  // todo
  X addHead(X value) {
    // contain
    {
      X xx = null;
      for (X x in _sequential) {
        if (x == value) {
          xx = x;
          break;
        }
      }
      if (xx != null) {
        _sequential.remove(xx);
        if(_sequential.length > 0) {
          _sequential.insert(0, xx);
        } else {
          _sequential.add(xx);
        }
        return xx;
      }
    }
    if(_sequential.length > 0) {
      _sequential.insert(0,value);
    } else {
      _sequential.add(value);      
    }
    _shuffled.add(value);
    return value;
  }

  void removeWithFilter(bool filter(X xx)) {
    List<X> t = [];
    for (X x in _sequential) {
      if (filter(x)) {
        t.add(x);
      }
    }
    for (X x in t) {
      _sequential.remove(x);
      _shuffled.remove(x);
    }
  }

  void clearAll() {
    _sequential.clear();
    _shuffled.clear();
  }

  void removeHead() {
    if (_sequential.length <= 0) {
      return;
    }
    X value = _sequential.removeAt(0);
    _shuffled.remove(value);
  }

  void shuffle() {
    List<X> items = _shuffled;
    var random = new math.Random();
    for (int i = 0; i < items.length; i++) {
      int n = random.nextInt(items.length);
      Object temp = items[i];
      items[i] = items[n];
      items[n] = temp;
    }
  }

  int get length => _sequential.length;
  X getShuffled(int index) {
    return _shuffled[index];
  }

  X getSequential(int index) {
    return _sequential[index];
  }
}
