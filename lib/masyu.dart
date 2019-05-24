import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MasyuApp());

const Wikipedia_Masyu_Example = [
  '..O.O.....',
  '....O...@.',
  '..@.@.O...',
  '...O..O...',
  '@....O...O',
  '..O....O..',
  '..@...O...',
  'O...@....O',
  '......OO..',
  '..@......@',
];

const Wikipedia_Masyu_Solution = [
  [0, 1], [0, 5], [1, 5], [1, 3], [4, 3], [4, 4], [2, 4], [2, 7],
  [3, 7], [3, 5], [6, 5], [6, 7], [4, 7], [4, 8], [1, 8], [1, 6],
  [0, 6], [0, 9], [5, 9], [5, 8], [6, 8], [6, 9], [9, 9], [9, 5],
  [8, 5], [8, 8], [7, 8], [7, 4], [9, 4], [9, 2], [6, 2], [6, 4],
  [5, 4], [5, 1], [8, 1], [8, 0], [4, 0], [4, 2], [2, 2], [2, 0],
  [1, 0], [1, 1],
];

_launchHelpURL() async {
  const url = 'https://en.wikipedia.org/wiki/Masyu';
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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MasyuHomePageState createState() =>
      _MasyuHomePageState(Wikipedia_Masyu_Example,
                          Wikipedia_Masyu_Solution);
}

bool moreThanTwoPaths(int paths) {
  paths &= paths-1;
  paths &= paths-1;
  return paths > 0;
}

const int CELL_EMPTY = 0;
const int CELL_OPEN_CIRCLE = 1;
const int CELL_FILL_CIRCLE = 2;

const int PATH_UP = 1;
const int PATH_DN = 2;
const int PATH_LT = 4;
const int PATH_RT = 8;

class Dir {
  final int dr;
  final int dc;
  final int fromDir;
  final int toDir;

  const Dir({this.dr, this.dc, this.fromDir, this.toDir});
}

const Dir DIR_UP    = Dir(dr: -1, dc:  0, fromDir: PATH_UP, toDir: PATH_DN);
const Dir DIR_DOWN  = Dir(dr:  1, dc:  0, fromDir: PATH_DN, toDir: PATH_UP);
const Dir DIR_LEFT  = Dir(dr:  0, dc: -1, fromDir: PATH_LT, toDir: PATH_RT);
const Dir DIR_RIGHT = Dir(dr:  0, dc:  1, fromDir: PATH_RT, toDir: PATH_LT);

int _constraintFor(String cellChar) {
  switch (cellChar) {
    case 'O': return CELL_OPEN_CIRCLE;
    case '@': return CELL_FILL_CIRCLE;
    default: return CELL_EMPTY;
  }
}

class _MasyuCellPainter extends CustomPainter {
  final int constraint;
  ValueNotifier<int> pathNotifier;

  _MasyuCellPainter(this.constraint, [int initPaths = 0]) {
    this.pathNotifier = ValueNotifier(initPaths);
  }

  @override
  void addListener(VoidCallback listener) {
    pathNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    pathNotifier.removeListener(listener);
  }

  addPath(int dir) {
    switch (dir) {
      case PATH_UP:
      case PATH_DN:
      case PATH_LT:
      case PATH_RT:
        pathNotifier.value ^= dir;
        break;
    }
  }

  clearPath() {
    pathNotifier.value = 0;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
//    print('paint(size=$size, constraint=$constraint, paths=$paths.value)');
    int paths = pathNotifier.value;

    Rect bounds = Rect.fromLTWH(0.0, 0.0, size.width, size.height);
    var minDim = min(size.width, size.height);
    var radius = minDim * 0.375;
    var pathW = max(2.0, minDim * 0.125);

    var paint = Paint();

    canvas.clipRect(bounds);

    // background
    paint.color = Colors.white;
    canvas.drawRect(bounds, paint);

    // constraint
    paint.color = Colors.black;
    if (constraint == CELL_FILL_CIRCLE) canvas.drawCircle(bounds.center, radius, paint);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    if (constraint == CELL_OPEN_CIRCLE) canvas.drawCircle(bounds.center, radius, paint);

    // border
    paint.color = Colors.blueGrey;
    paint.strokeWidth = 1;
    canvas.drawRect(bounds, paint);

    // paths
    paint.color = moreThanTwoPaths(paths) ? Colors.red : Colors.blue;
    paint.strokeWidth = pathW;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    if ((paths & PATH_UP) != 0) canvas.drawLine(bounds.center, bounds.topCenter,    paint);
    if ((paths & PATH_DN) != 0) canvas.drawLine(bounds.center, bounds.bottomCenter, paint);
    if ((paths & PATH_LT) != 0) canvas.drawLine(bounds.center, bounds.centerLeft,   paint);
    if ((paths & PATH_RT) != 0) canvas.drawLine(bounds.center, bounds.centerRight,  paint);
  }
}

class _MasyuHomePageState extends State<MasyuHomePage> {
  List<List<CustomPaint>> _cells;
  List<List<int>> _solution;
  bool _dragging = false;
  int _dragRow;
  int _dragCol;

  _MasyuHomePageState(List<String> puzzleSpec, [this._solution]) {
    var nRows = puzzleSpec.length;
    var nCols = puzzleSpec[0].length;
    _cells = List<List<CustomPaint>>
        .generate(nRows, (row) => List<CustomPaint>
        .generate(nCols, (col) => CustomPaint(
//            size: Size(20, 20),
            key: GlobalKey(),
            isComplex: true,
            willChange: true,
            painter: _MasyuCellPainter(_constraintFor(puzzleSpec[row][col])),
            child: Container(width: 40, height: 40),
    )));
  }

  markPath(int dir) {
    _MasyuCellPainter painter = _cells[_dragRow][_dragCol].painter;
    painter.addPath(dir);
  }

  move(Dir dir) {
    markPath(dir.fromDir);
    _dragRow += dir.dr;
    _dragCol += dir.dc;
    markPath(dir.toDir);
  }

  moveTo(int row, int col) {
    while (_dragRow != row || _dragCol != col) {
      int dRow = row - _dragRow;
      int dCol = col - _dragCol;
      if (dRow.abs() > dCol.abs()) {
        if (dRow > 0) { move(DIR_DOWN);  } else { move(DIR_UP);    }
      } else {
        if (dCol > 0) { move(DIR_RIGHT); } else { move(DIR_LEFT);  }
      }
    }
  }

  clear() {
    for (int row = 0; row < _cells.length; row++) {
      for (int col = 0; col < _cells[row].length; col++) {
        _MasyuCellPainter painter = _cells[row][col].painter;
        painter.clearPath();
      }
    }
    _dragging = false;
  }

  solve() {
    clear();
    _dragging = true;
    _dragRow = _solution[_solution.length - 1][0];
    _dragCol = _solution[_solution.length - 1][1];
    for (int i = 0; i < _solution.length; i++) {
      moveTo(_solution[i][0], _solution[i][1]);
    }
    _dragging = false;
  }

  doDrag(Offset pos) {
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

  dragStop() => _dragging = false;

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
        title: Text(widget.title),
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
      bottomSheet: Row(
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
            onPressed: _solution == null ? null : () => solve(),
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}
