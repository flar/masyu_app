import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'puzzles.dart';

void main() => runApp(MasyuApp());

void _launchHelpURL() {
  _launchURL('https://en.wikipedia.org/wiki/Masyu#Rules');
}

void _launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class MasyuApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masyu Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MasyuHomePage(title: 'Masyu Demo Home Page'),
    );
  }
}

class MasyuHomePage extends StatefulWidget {
  MasyuHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MasyuHomePageState createState() => _MasyuHomePageState(kPuzzles[1]);
}

class PathDirection {
  final int rowDelta;
  final int colDelta;

  const PathDirection._PathDirection(this.rowDelta, this.colDelta);

  static const up    = PathDirection._PathDirection(-1,  0);
  static const down  = PathDirection._PathDirection( 1,  0);
  static const left  = PathDirection._PathDirection( 0, -1);
  static const right = PathDirection._PathDirection( 0,  1);

  PathDirection get reverseDirection {
    switch (this) {
      case up: return down;
      case down: return up;
      case left: return right;
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

  int _pathMask;

  PathSet([this._pathMask = 0]);

  bool goesUp()    => (_pathMask & _upBit) != 0;
  bool goesDown()  => (_pathMask & _dnBit) != 0;
  bool goesLeft()  => (_pathMask & _ltBit) != 0;
  bool goesRight() => (_pathMask & _rtBit) != 0;

  void clear() => _pathMask = 0;

  void goUp()    => _pathMask |= _upBit;
  void goDown()  => _pathMask |= _dnBit;
  void goLeft()  => _pathMask |= _ltBit;
  void goRight() => _pathMask |= _rtBit;

  void go(PathDirection p) {
    switch (p) {
      case PathDirection.up:    goUp();    break;
      case PathDirection.down:  goDown();  break;
      case PathDirection.left:  goLeft();  break;
      case PathDirection.right: goRight(); break;
    }
  }

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

const int PATH_UP = 1;
const int PATH_DN = 2;
const int PATH_LT = 4;
const int PATH_RT = 8;

class Direction {
  final int rowDelta;
  final int colDelta;
  final int fromDir;
  final int toDir;

  const Direction(this.rowDelta, this.colDelta, this.fromDir, this.toDir);

  static const up    = Direction(-1,  0, PATH_UP, PATH_DN);
  static const down  = Direction( 1,  0, PATH_DN, PATH_UP);
  static const left  = Direction( 0, -1, PATH_LT, PATH_RT);
  static const right = Direction( 0,  1, PATH_RT, PATH_LT);
}

class _MasyuCellPainter extends CustomPainter {
  final int constraint;
  ValueNotifier<int> pathMaskNotifier;

  _MasyuCellPainter({@required this.constraint, int initPathMask = 0}) {
    this.pathMaskNotifier = ValueNotifier(initPathMask);
  }

  @override
  void addListener(VoidCallback listener) {
    pathMaskNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    pathMaskNotifier.removeListener(listener);
  }

  void addPath(int dir) {
    switch (dir) {
      case PATH_UP:
      case PATH_DN:
      case PATH_LT:
      case PATH_RT:
        pathMaskNotifier.value ^= dir;
        break;
      default:
        throw 'Unrecognized path direction: $dir';
    }
  }

  void clearPath() {
    pathMaskNotifier.value = 0;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  /**
   * Determine if more than two paths are indicated for the cell by counting
   * the bits in the bitmask of its paths.
   */
  bool _moreThanTwoPaths(int pathmask) {
    pathmask &= pathmask-1;
    pathmask &= pathmask-1;
    return pathmask > 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
//    print('paint(size=$size, constraint=$constraint, paths=$paths.value)');
    final int pathMask = pathMaskNotifier.value;

    final Rect bounds = Rect.fromLTWH(0.0, 0.0, size.width, size.height);
    final double minDim = min(size.width, size.height);
    final double radius = minDim * 0.375;
    final double pathW = max(2.0, minDim * 0.125);

    final Paint paint = Paint();

    canvas.clipRect(bounds);

    // background
    paint.color = Colors.white;
    canvas.drawRect(bounds, paint);

    // constraint
    paint.color = Colors.black;
    if (constraint == CellType.filledCircle) canvas.drawCircle(bounds.center, radius, paint);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    if (constraint == CellType.openCircle) canvas.drawCircle(bounds.center, radius, paint);

    // border
    paint.color = Colors.blueGrey;
    paint.strokeWidth = 1;
    canvas.drawRect(bounds, paint);

    // paths
    paint.color = _moreThanTwoPaths(pathMask) ? Colors.red : Colors.blue;
    paint.strokeWidth = pathW;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    if ((pathMask & PATH_UP) != 0) canvas.drawLine(bounds.center, bounds.topCenter,    paint);
    if ((pathMask & PATH_DN) != 0) canvas.drawLine(bounds.center, bounds.bottomCenter, paint);
    if ((pathMask & PATH_LT) != 0) canvas.drawLine(bounds.center, bounds.centerLeft,   paint);
    if ((pathMask & PATH_RT) != 0) canvas.drawLine(bounds.center, bounds.centerRight,  paint);
  }
}

class _MasyuHomePageState extends State<MasyuHomePage> {
  MasyuPuzzle puzzle;
  List<List<CustomPaint>> _cells;
  bool _dragging = false;
  int _dragRow;
  int _dragCol;

  _MasyuHomePageState(this.puzzle) {
    _cells = toCells(puzzle);
  }

  void setPuzzle(MasyuPuzzle puzzle) {
    List<List<CustomPaint>> cells = toCells(puzzle);
    setState(() {
      this.puzzle = puzzle;
      this._cells = cells;
      this._dragging = false;
    });
  }

  List<List<CustomPaint>> toCells(MasyuPuzzle puzzle) {
    return List<List<CustomPaint>>
        .generate(puzzle.numRows, (row) => List<CustomPaint>
        .generate(puzzle.numCols, (col) => CustomPaint(
//            size: Size(20, 20),
      key: GlobalKey(),
      isComplex: true,
      willChange: true,
      painter: _MasyuCellPainter(constraint: CellType.forSpecChar(puzzle.gridSpec[row][col])),
      child: Container(width: 40, height: 40),
    )));
  }

  void markPath(int dir) {
    _MasyuCellPainter painter = _cells[_dragRow][_dragCol].painter;
    painter.addPath(dir);
  }

  void move(Direction dir) {
    markPath(dir.fromDir);
    _dragRow += dir.rowDelta;
    _dragCol += dir.colDelta;
    markPath(dir.toDir);
  }

  void moveTo(int row, int col) {
    while (_dragRow != row || _dragCol != col) {
      int dRow = row - _dragRow;
      int dCol = col - _dragCol;
      if (dRow.abs() > dCol.abs()) {
        if (dRow > 0) { move(Direction.down);  } else { move(Direction.up);    }
      } else {
        if (dCol > 0) { move(Direction.right); } else { move(Direction.left);  }
      }
    }
  }

  void clear() {
    for (int row = 0; row < _cells.length; row++) {
      for (int col = 0; col < _cells[row].length; col++) {
        _MasyuCellPainter painter = _cells[row][col].painter;
        painter.clearPath();
      }
    }
    _dragging = false;
  }

  void solve() {
    clear();
    List<List<int>> path = puzzle.solution;
    _dragging = true;
    _dragRow = path.last[0];
    _dragCol = path.last[1];
    path.forEach((pt) => moveTo(pt[0], pt[1]));
    _dragging = false;
  }

  Widget _title() {
    if (puzzle == null) {
      return Text('No puzzle loaded');
    }
    if (puzzle.author == null) {
      return Text(puzzle.description ?? 'Unknown puzzle');
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(puzzle.description ?? 'Unknown puzzle', textAlign: TextAlign.left),
        Text('by ${puzzle.author}', textAlign: TextAlign.right),
      ],
    );
  }

  void doDrag(Offset pos) {
    for (int row = 0; row < _cells.length; row++) {
      for (int col = 0; col < _cells[row].length; col++) {
        GlobalKey key = _cells[row][col].key;
        RenderBox rb = key.currentContext.findRenderObject();
        Rect bounds = rb.paintBounds;
        Offset lPos = rb.globalToLocal(pos);
        if (bounds.contains(lPos)) {
          if (_dragging) {
            moveTo(row, col);
          } else {
            _dragging = true;
            _dragRow = row;
            _dragCol = col;
          }
          return;
        }
      }
    }
  }

  void dragStop() => _dragging = false;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: _title(),
      ),
      drawer: Drawer(
        child: ListView(
          children: [...kPuzzles.map((puzzle) => ListTile(
            title: Text(puzzle.description),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              setPuzzle(puzzle);
              Navigator.of(context).pop();
            }
          ))],
        )
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: GestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(_cells.length, (i) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _cells[i]
              ),
            ),
          ),
          onPanDown: (details) => doDrag(details.globalPosition),
          onPanUpdate: (details) => doDrag(details.globalPosition),
          onPanEnd: (details) => dragStop(),
          onPanCancel: () => dragStop(),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(flex: 2),
            RaisedButton(
              child: Text('How to Play'),
              onPressed: _launchHelpURL,
            ),
            Spacer(),
            RaisedButton(
              child: Text('Clear'),
              onPressed: () => clear(),
            ),
            Spacer(),
            RaisedButton(
              child: Text('Show Solution'),
              onPressed: puzzle.solution == null ? null : () => solve(),
            ),
            Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
