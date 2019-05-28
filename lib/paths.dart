import 'package:flutter/material.dart';

class PathDirection {
  final int rowDelta;
  final int colDelta;

  const PathDirection._internal(this.rowDelta, this.colDelta);

  static const up    = PathDirection._internal(-1,  0);
  static const down  = PathDirection._internal( 1,  0);
  static const left  = PathDirection._internal( 0, -1);
  static const right = PathDirection._internal( 0,  1);

  PathDirection get reverse {
    switch (this) {
      case up:    return down;
      case down:  return up;
      case left:  return right;
      case right: return left;
      default: throw 'Unrecognized path direction $this';
    }
  }
}

class PathSet {
  static const _upBit = 1;
  static const _dnBit = 2;
  static const _ltBit = 4;
  static const _rtBit = 8;

  final ValueNotifier<int> pathMaskNotifier = new ValueNotifier(0);
  int get _pathMask => pathMaskNotifier.value;
  set _pathMask(int m) => pathMaskNotifier.value = m;

  bool goesUp()    => (_pathMask & _upBit) != 0;
  bool goesDown()  => (_pathMask & _dnBit) != 0;
  bool goesLeft()  => (_pathMask & _ltBit) != 0;
  bool goesRight() => (_pathMask & _rtBit) != 0;

  void clear() => _pathMask = 0;

  void flipUp()    => _pathMask ^= _upBit;
  void flipDown()  => _pathMask ^= _dnBit;
  void flipLeft()  => _pathMask ^= _ltBit;
  void flipRight() => _pathMask ^= _rtBit;

  void flip(PathDirection p) {
    switch (p) {
      case PathDirection.up:    flipUp();    break;
      case PathDirection.down:  flipDown();  break;
      case PathDirection.left:  flipLeft();  break;
      case PathDirection.right: flipRight(); break;
    }
  }

  int pathCount() {
    switch (_pathMask) {
      case 0:
        return 0;
      case 1:case 2:case 4:case 8:
      return 1;
      case 3:case 5:case 6:case 9:case 10:case 12:
      return 2;
      case 7:case 11:case 13:case 14:
      return 3;
      case 15:
        return 4;
      default:
        throw 'Bad path mask: $_pathMask';
    }
  }
}

class PathLocation {
  int row;
  int col;

  PathLocation(this.row, this.col);

  void move(PathDirection dir) {
    this.row += dir.rowDelta;
    this.col += dir.colDelta;
  }

  bool isAt(int row, int col) => this.row == row && this.col == col;
}
