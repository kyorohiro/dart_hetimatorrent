library hetimatorrent.torrent.pieceinfo;
import 'dart:core';

class PieceInfo {
  int start = 0;
  int end = 0;
  PieceInfo(int start, int end) {
    this.start = start;
    this.end = end;
  }
}


class PieceInfoList {
  List<PieceInfo> mInfo = new List<PieceInfo>();

   int size() {
    return mInfo.length;
  }

  PieceInfo getPieceInfo(int index) {
    return mInfo[index];
  }

  void append(int start, int end) {
    mInfo.add(new PieceInfo(start, end));
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
    mInfo.sort((PieceInfo a, PieceInfo b) {
      return a.start - b.start;
    });
  }

  void normalize() {
    sort();
    for(int i=0;i<mInfo.length-1;) {
      PieceInfo bef = mInfo[i];
      PieceInfo aft = mInfo[i+1];
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