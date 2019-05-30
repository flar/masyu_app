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

  static PathDirection bestStepFor(int rowDelta, int colDelta) {
    if (rowDelta.abs() > colDelta.abs()) {
      return (rowDelta < 0) ? up : down;
    } else {
      return (colDelta < 0) ? left : right;
    }
  }
}

class PathSet implements Listenable {
  static const _upBit = 1;
  static const _dnBit = 2;
  static const _ltBit = 4;
  static const _rtBit = 8;

  final ValueNotifier<int> _pathMaskNotifier = new ValueNotifier(0);
  int get _pathMask => _pathMaskNotifier.value;
  set _pathMask(int m) => _pathMaskNotifier.value = m;

  @override
  void addListener(VoidCallback listener) {
    _pathMaskNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _pathMaskNotifier.removeListener(listener);
  }

  bool goesUp()    => (_pathMask & _upBit) != 0;
  bool goesDown()  => (_pathMask & _dnBit) != 0;
  bool goesLeft()  => (_pathMask & _ltBit) != 0;
  bool goesRight() => (_pathMask & _rtBit) != 0;

  void setUp()    => _pathMask |= _upBit;
  void setDown()  => _pathMask |= _dnBit;
  void setLeft()  => _pathMask |= _ltBit;
  void setRight() => _pathMask |= _rtBit;

  void set(PathDirection p) {
    switch (p) {
      case PathDirection.up:    setUp();    break;
      case PathDirection.down:  setDown();  break;
      case PathDirection.left:  setLeft();  break;
      case PathDirection.right: setRight(); break;
    }
  }

  void clearUp()    => _pathMask &= ~_upBit;
  void clearDown()  => _pathMask &= ~_dnBit;
  void clearLeft()  => _pathMask &= ~_ltBit;
  void clearRight() => _pathMask &= ~_rtBit;

  void clear(PathDirection p) {
    switch (p) {
      case PathDirection.up:    clearUp();    break;
      case PathDirection.down:  clearDown();  break;
      case PathDirection.left:  clearLeft();  break;
      case PathDirection.right: clearRight(); break;
    }
  }

  void clearAll() => _pathMask = 0;

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

  static const _bitCounts = [
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
  ];

  int pathCount() => _bitCounts[_pathMask];
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
