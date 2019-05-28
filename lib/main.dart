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

class _MasyuCellPainter extends CustomPainter {
  final int constraint;
  final PathSet paths = new PathSet();

  _MasyuCellPainter({@required this.constraint});

  @override
  void addListener(VoidCallback listener) {
    paths.pathMaskNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    paths.pathMaskNotifier.removeListener(listener);
  }

  void flipPath(PathDirection direction) {
    paths.flip(direction);
  }

  void clearPath() {
    paths.clear();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
//    print('paint(size=$size, constraint=$constraint, paths=$paths.value)');

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
    paint.color = paths.pathCount() > 2 ? Colors.red : Colors.blue;
    paint.strokeWidth = pathW;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    if (paths.goesUp())    canvas.drawLine(bounds.center, bounds.topCenter,    paint);
    if (paths.goesDown())  canvas.drawLine(bounds.center, bounds.bottomCenter, paint);
    if (paths.goesLeft())  canvas.drawLine(bounds.center, bounds.centerLeft,   paint);
    if (paths.goesRight()) canvas.drawLine(bounds.center, bounds.centerRight,  paint);
  }
}

class _MasyuHomePageState extends State<MasyuHomePage> {
  MasyuPuzzle puzzle;
  List<List<CustomPaint>> _cells;
  PathLocation _drag;

  _MasyuHomePageState(this.puzzle) {
    _cells = toCells(puzzle);
  }

  void setPuzzle(MasyuPuzzle puzzle) {
    List<List<CustomPaint>> cells = toCells(puzzle);
    setState(() {
      this.puzzle = puzzle;
      this._cells = cells;
      this._drag = null;
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

  void markPath(PathDirection dir) {
    _MasyuCellPainter painter = _cells[_drag.row][_drag.col].painter;
    painter.flipPath(dir);
  }

  void move(PathDirection dir) {
    markPath(dir);
    _drag.move(dir);
    markPath(dir.reverse);
  }

  void moveTo(int row, int col) {
    while (!_drag.isAt(row, col)) {
      int dRow = row - _drag.row;
      int dCol = col - _drag.col;
      if (dRow.abs() > dCol.abs()) {
        if (dRow > 0) { move(PathDirection.down);  } else { move(PathDirection.up);    }
      } else {
        if (dCol > 0) { move(PathDirection.right); } else { move(PathDirection.left);  }
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
    _drag = null;
  }

  void solve() {
    clear();
    List<List<int>> path = puzzle.solution;
    _drag = PathLocation(path.last[0], path.last[1]);
    path.forEach((pt) => moveTo(pt[0], pt[1]));
    _drag = null;
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
          if (_drag == null) {
            _drag = PathLocation(row, col);
          } else {
            moveTo(row, col);
          }
          return;
        }
      }
    }
  }

  void dragStop() => _drag = null;

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
