import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'puzzles.dart';
import 'paths.dart';

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
        primarySwatch: Colors.blue,
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
    _cells = _toCells(puzzle);
  }

  void _setPuzzle(MasyuPuzzle puzzle) {
    List<List<CustomPaint>> cells = _toCells(puzzle);
    setState(() {
      this.puzzle = puzzle;
      this._cells = cells;
      this._drag = null;
    });
  }

  List<List<CustomPaint>> _toCells(MasyuPuzzle puzzle) {
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

  void _markPath(PathDirection dir) {
    _MasyuCellPainter painter = _cells[_drag.row][_drag.col].painter;
    painter.flipPath(dir);
  }

  void _move(PathDirection dir) {
    _markPath(dir);
    _drag.move(dir);
    _markPath(dir.reverse);
  }

  void _moveTo(int row, int col) {
    while (!_drag.isAt(row, col)) {
      int dRow = row - _drag.row;
      int dCol = col - _drag.col;
      if (dRow.abs() > dCol.abs()) {
        if (dRow > 0) { _move(PathDirection.down);  } else { _move(PathDirection.up);    }
      } else {
        if (dCol > 0) { _move(PathDirection.right); } else { _move(PathDirection.left);  }
      }
    }
  }

  void _clearPath() {
    for (int row = 0; row < _cells.length; row++) {
      for (int col = 0; col < _cells[row].length; col++) {
        _MasyuCellPainter painter = _cells[row][col].painter;
        painter.clearPath();
      }
    }
    _drag = null;
  }

  void _showSolution() {
    _clearPath();
    List<List<int>> path = puzzle.solution;
    _drag = PathLocation(path.last[0], path.last[1]);
    path.forEach((pt) => _moveTo(pt[0], pt[1]));
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

  void _doDrag(Offset pos) {
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
            _moveTo(row, col);
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
          children: [
            DrawerHeader(
              child: Text('Available puzzles'),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            for (var puzzle in kPuzzles)
              ListTile(
                title: Text(puzzle.description),
                subtitle: Text(puzzle.author),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  _setPuzzle(puzzle);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: GestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var row in _cells)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row,
                ),
            ],
          ),
          onPanDown: (details) => _doDrag(details.globalPosition),
          onPanUpdate: (details) => _doDrag(details.globalPosition),
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
              onPressed: () => _clearPath(),
            ),
            Spacer(),
            RaisedButton(
              child: Text('Show Solution'),
              onPressed: puzzle.solution == null ? null : () => _showSolution(),
            ),
            Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
