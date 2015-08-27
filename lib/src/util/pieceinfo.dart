library hetimatorrent.util.pieceinfo;
import 'dart:core';

class PieceInfoItem {
  int start = 0;
  int end = 0;
  PieceInfoItem(int start, int end) {
    this.start = start;
    this.end = end;
  }
}


class PieceInfo {
  List<PieceInfoItem> mInfo = new List<PieceInfoItem>();

  List<int> getFreeSpace(int size) {
    int begin = 0;
    for(PieceInfoItem info in mInfo) {
      if(info.start > begin && begin != info.start) {
        return [begin, info.start];
      } else {
        begin = info.end;
      }
    }
    return [begin, begin+size];
  }

  int size() {
    return mInfo.length;
  }

  PieceInfoItem getPieceInfo(int index) {
    return mInfo[index];
  }

  void append(int start, int end) {
    mInfo.add(new PieceInfoItem(start, end));
    normalize();
  }

  // #patternA
  // <-----><----->
  //    <------>
  //    ↑start　↑end
  //
  // #patternB
  // <-----><----->
  //   <->
  //
  //
  // #patternC
  //  <-----><----->
  // <-------->
  //
  //
  void remove(int start, int end) {
    for(int i=0;i<mInfo.length;) {
      int _s = mInfo[i].start;
      int _e = mInfo[i].end;

      if(end<_e&&end<_s){
        break;
      }
      
      //#pattern B
      if(_s<=start&&start<_e&&_s<=end&&end<_e) {
        int prevE = mInfo[i].end;
        mInfo[i].end = start;
        append(end, prevE);
        break;
      } 
      // #pattern C
      else if(start<=_s&&_s<end&&start<=_e&&_e<end) {
        mInfo.remove(mInfo[i]);       
      }
      // #pattern A
      else {
        if(_s<=start&&start<_e) {
          mInfo[i].end = start;
        } 
        if(_s<=end&&end<_e){
          mInfo[i].start = end;
        }
        if(mInfo[i].start>=mInfo[i].end) {
          mInfo.remove(mInfo[i]);
        } else {
          i++;
        }
      }
    }
  }

  void sort() {
    mInfo.sort((PieceInfoItem a, PieceInfoItem b) {
      return a.start - b.start;
    });
  }

  void normalize() {
    sort();
    for(int i=0;i<mInfo.length-1;) {
      PieceInfoItem bef = mInfo[i];
      PieceInfoItem aft = mInfo[i+1];
      if(bef.end >= aft.start) {
        int end = bef.end;
        if(end<aft.end) {
          end = aft.end;
        }
        bef.end = end;
        mInfo.remove(aft);
      } else {
        i++;
      }
    }
  }
}