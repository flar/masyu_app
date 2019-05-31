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

class _MasyuCellState implements Listenable {
  static const _constraintErrorBit = 1;
  static const _pathErrorBit       = 2;
  static const _pathHighlightBit   = 4;

  final ValueNotifier<int> _state;

  _MasyuCellState() : _state = ValueNotifier(0);

  bool get constraintError => (_state.value & _constraintErrorBit) != 0;
  bool get pathError       => (_state.value & _pathErrorBit)       != 0;
  bool get pathHighlight   => (_state.value & _pathHighlightBit)   != 0;
  set constraintError(bool newState) => _setState(_constraintErrorBit, newState);
  set pathError      (bool newState) => _setState(_pathErrorBit,       newState);
  set pathHighlight  (bool newState) => _setState(_pathHighlightBit,   newState);

  void _setState(int stateBit, bool newState) {
    if (newState) {
      _state.value |= stateBit;
    } else {
      _state.value &= ~stateBit;
    }
  }

  void clear() => _state.value = 0;

  @override
  void addListener(VoidCallback listener) {
    _state.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _state.removeListener(listener);
  }
}

class _MasyuCell implements Listenable {
  final CellType constraint;
  final PathSet paths;
  final _MasyuCellState state;
  _MasyuCell upward;
  _MasyuCell downward;
  _MasyuCell leftward;
  _MasyuCell rightward;

  _MasyuCell({@required this.constraint})
      : paths = PathSet(),
        state = _MasyuCellState();

  void clear() {
    paths.clearAll();
    state.clear();
  }

  void flip(PathDirection dir) {
    paths.flip(dir);
    state.pathError = paths.pathCount() > 2;
    checkConstraint();
    checkNeighbors();
  }

  bool goesUp()    => paths.goesUp();
  bool goesDown()  => paths.goesDown();
  bool goesLeft()  => paths.goesLeft();
  bool goesRight() => paths.goesRight();

  bool goesHorizontal() => goesLeft() || goesRight();
  bool goesVertical()   => goesUp()   || goesDown();

  void checkNeighbors() {
    upward   ?.checkConstraint();
    downward ?.checkConstraint();
    leftward ?.checkConstraint();
    rightward?.checkConstraint();
  }

  void checkConstraint() {
    switch (constraint) {
      case CellType.empty:
        state.constraintError = false;
        break;
      case CellType.openCircle:
        state.constraintError = _hasOpenConstraintError();
        break;
      case CellType.filledCircle:
        state.constraintError = _checkFilledConstraint();
        break;
    }
  }

  bool _hasOpenConstraintError() {
    if (goesHorizontal() && goesVertical()) return true;

    if (goesUp()   && upward  .goesUp() &&
        goesDown() && downward.goesDown())
    {
      return true;
    }
    if (goesLeft()  && leftward .goesLeft() &&
        goesRight() && rightward.goesRight())
    {
      return true;
    }

    return false;
  }

  bool _checkFilledConstraint() {
    if (goesUp()   && goesDown())  return true;
    if (goesLeft() && goesRight()) return true;

    if (goesUp()    && upward   .goesHorizontal()) return true;
    if (goesDown()  && downward .goesHorizontal()) return true;
    if (goesLeft()  && leftward .goesVertical())   return true;
    if (goesRight() && rightward.goesVertical())   return true;

    return false;
  }

  _MasyuCellPainter _painter;
  _MasyuCellPainter get painter => _painter ??= _MasyuCellPainter(this);
  Key _key;
  Key get key => _key ??= GlobalKey();

  @override
  void addListener(VoidCallback listener) {
    paths.addListener(listener);
    state.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    paths.removeListener(listener);
    state.removeListener(listener);
  }
}

class _MasyuGrid {
  final MasyuPuzzle puzzle;
  final List<_MasyuCell> cells;
  int get numRows => puzzle.numRows;
  int get numCols => puzzle.numCols;

  _MasyuGrid({@required this.puzzle}) : cells = [
    for (var row in puzzle.constraints)
      for (var constraint in row)
        _MasyuCell(constraint: constraint),
  ] {
    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numCols; col++) {
        if (row > 0)         cell(row, col).upward    = cell(row-1, col);
        if (row < numRows-1) cell(row, col).downward  = cell(row+1, col);
        if (col > 0)         cell(row, col).leftward  = cell(row, col-1);
        if (col < numCols-1) cell(row, col).rightward = cell(row, col+1);
      }
    }
  }

  _MasyuCell cell(int row, int col) {
    return cells[row * numCols + col];
  }

  void clear() {
    for (var cell in cells) cell.clear();
  }

  PathLocation hit(Offset pos) {
    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numCols; col++) {
        GlobalKey key = cell(row, col).key;
        RenderBox rb = key.currentContext.findRenderObject();
        Rect bounds = rb.paintBounds;
        Offset lPos = rb.globalToLocal(pos);
        if (bounds.contains(lPos)) {
          return PathLocation(row, col);
        }
      }
    }
    return null;
  }

  List<_MasyuCell> row(int row) {
    int start = row * numCols;
    int end = start + numCols;
    return cells.sublist(start, end);
  }

  Iterable<List<_MasyuCell>> get rows =>
      Iterable.generate(numRows, (index) => row(index));
}

class _MasyuCellPainter extends CustomPainter {
  final _MasyuCell _cell;

  _MasyuCellPainter(this._cell);

  @override
  void addListener(VoidCallback listener) {
    _cell.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _cell.removeListener(listener);
  }

  bool _isFilledCircle() => _cell.constraint == CellType.filledCircle;
  bool _isOpenCircle()   => _cell.constraint == CellType.openCircle;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
//    print('paint(size=$size, constraint=$constraint, paths=$paths.value)');

    final Rect bounds = Rect.fromLTWH(0.0, 0.0, size.width, size.height);
    final Offset center = bounds.center;
    final double minDim = min(size.width, size.height);
    final double radius = minDim * 0.375;
    final double pathW = max(2.0, minDim * 0.125);

    final Paint paint = Paint();

    canvas.clipRect(bounds);

    // background
    paint.color = Colors.white;
    canvas.drawRect(bounds, paint);

    // constraint
    paint.color = _cell.state.constraintError ? Colors.red.shade900 : Colors.black;
    if (_isFilledCircle()) canvas.drawCircle(center, radius, paint);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    if (_isOpenCircle()) canvas.drawCircle(center, radius, paint);

    // border
    paint.color = Colors.blueGrey;
    paint.strokeWidth = 1;
    canvas.drawRect(bounds, paint);

    // paths
    paint.color = _cell.state.pathError ? Colors.red : Colors.blue;
    paint.strokeWidth = pathW;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    if (_cell.goesUp())    canvas.drawLine(center, bounds.topCenter,    paint);
    if (_cell.goesDown())  canvas.drawLine(center, bounds.bottomCenter, paint);
    if (_cell.goesLeft())  canvas.drawLine(center, bounds.centerLeft,   paint);
    if (_cell.goesRight()) canvas.drawLine(center, bounds.centerRight,  paint);
  }
}

class _MasyuHomePageState extends State<MasyuHomePage> {
  MasyuPuzzle puzzle;
  _MasyuGrid grid;
  PathLocation _drag;

  _MasyuHomePageState(this.puzzle) {
    grid = _MasyuGrid(puzzle: puzzle);
  }

  void _setPuzzle(MasyuPuzzle puzzle) {
    _MasyuGrid grid = _MasyuGrid(puzzle: puzzle);
    setState(() {
      this.puzzle = puzzle;
      this.grid = grid;
      this._drag = null;
    });
  }

  void _markPath(PathDirection dir) {
    grid.cell(_drag.row, _drag.col).flip(dir);
  }

  void _move(PathDirection dir) {
    _markPath(dir);
    _drag.move(dir);
    _markPath(dir.reverse);
  }

  void _moveTo(int row, int col) {
    while (!_drag.isAt(row, col)) {
      _move(PathDirection.bestStepFor(row - _drag.row, col - _drag.col));
    }
  }

  void _clearPath() {
    for (var cell in grid.cells) cell.clear();
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
    PathLocation gridLocation = grid.hit(pos);
    if (gridLocation != null) {
      if (_drag == null) {
        _drag = gridLocation;
      } else {
        _moveTo(gridLocation.row, gridLocation.col);
      }
    }
  }

  void dragStop() {
    _drag = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        child: GestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var row in grid.rows)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var cell in row)
                      CustomPaint(
                        key: cell.key,
                        isComplex: true,
                        willChange: true,
                        painter: cell.painter,
                        child: Container(width: 40, height: 40),
                      ),
                  ],
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
