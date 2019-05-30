import 'package:flutter/material.dart';

class CellType {
  static const empty        = 0;
  static const openCircle   = 1;
  static const filledCircle = 2;

  static int forCodePoint(int codePoint) {
    switch (codePoint) {
      case 0x4f: return CellType.openCircle;
      case 0x40: return CellType.filledCircle;
      default: return CellType.empty;
    }
  }

  static int forSpecChar(String cellChar) {
    switch (cellChar) {
      case 'O': return CellType.openCircle;
      case '@': return CellType.filledCircle;
      default: return CellType.empty;
    }
  }
}

class MasyuPuzzle {
  final String description;
  final String srcURL;
  final String author;
  final String authorURL;
  final int numRows;
  final int numCols;
  final List<String> gridSpec;
  final List<List<int>> solution;

  const MasyuPuzzle({
    @required this.numRows,
    @required this.numCols,
    @required this.description,
              this.srcURL,
              this.author,
              this.authorURL,
    @required this.gridSpec,
              this.solution});
}

const List<MasyuPuzzle> kPuzzles = const [
  MasyuPuzzle(
      numRows: 10,
      numCols: 10,
      description: 'Wikipedia Masyu Example',
      srcURL:      'https://commons.wikimedia.org/wiki/File:Masyu_puzzle.svg',
      author:      'Adam R. Wood',
      authorURL:   'https://en.wikipedia.org/wiki/en:User:Zotmeister',
      gridSpec: const [
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
      ],
      solution: const [
        [0, 1], [0, 5], [1, 5], [1, 3], [4, 3], [4, 4], [2, 4], [2, 7],
        [3, 7], [3, 5], [6, 5], [6, 7], [4, 7], [4, 8], [1, 8], [1, 6],
        [0, 6], [0, 9], [5, 9], [5, 8], [6, 8], [6, 9], [9, 9], [9, 5],
        [8, 5], [8, 8], [7, 8], [7, 4], [9, 4], [9, 2], [6, 2], [6, 4],
        [5, 4], [5, 1], [8, 1], [8, 0], [4, 0], [4, 2], [2, 2], [2, 0],
        [1, 0], [1, 1],
      ]
  ),
  MasyuPuzzle(
      numRows: 8,
      numCols: 8,
      description: 'KrazyDad 8x8 Easy 1-1-1',
      srcURL:      'https://krazydad.com/tablet/masyu/?kind=8x8_d0&volumeNumber=1&bookNumber=1&puzzleNumber=1',
      author:      'Jim Bumgardner',
      authorURL:   'https://krazydad.com/about.php',
      gridSpec: const [
        '........',
        '.O.O....',
        '..OO..OO',
        '.O.O..O.',
        '@.......',
        '.......O',
        '.OOOOO..',
        '........',
      ],
      solution: const [
        [0, 0], [0, 1], [2, 1], [2, 4], [1, 4], [1, 2], [0, 2], [0, 5],
        [4, 5], [4, 6], [1, 6], [1, 7], [6, 7], [6, 6], [5, 6], [5, 5],
        [7, 5], [7, 4], [5, 4], [5, 3], [7, 3], [7, 2], [5, 2], [5, 1],
        [7, 1], [7, 0], [4, 0], [4, 4], [3, 4], [3, 0],
      ]
  ),
  /*
  MasyuPuzzle(
    numRows: 3,
    numCols: 3,
    description: 'Icon generation puzzle',
    author:      'Jim Graham',
    authorURL:   'mailto:flar@google.com',
    gridSpec: const [
      '@O@',
      'O.O',
      '@O@',
    ],
    solution: const [
      [0, 0], [0, 2], [2, 2], [2, 0],
    ],
  ),
  */
];