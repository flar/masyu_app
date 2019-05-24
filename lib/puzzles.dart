class MasyuPuzzle {
  final String description;
  final String srcURL;
  final String author;
  final String authorURL;
  final int numRows;
  final int numCols;
  final List<String> gridSpec;
  final List<List<int>> solution;

  const MasyuPuzzle(this.numRows, this.numCols,
      this.description, this.srcURL,
      this.author, this.authorURL,
      this.gridSpec, this.solution);
}

const List<MasyuPuzzle> PUZZLES = const [
  MasyuPuzzle(10, 10,
      'Wikipedia Masyu Example',
      'https://commons.wikimedia.org/wiki/File:Masyu_puzzle.svg',
      'Adam R. Wood',
      'https://en.wikipedia.org/wiki/en:User:Zotmeister',
      const [
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
      ], const [
        [0, 1], [0, 5], [1, 5], [1, 3], [4, 3], [4, 4], [2, 4], [2, 7],
        [3, 7], [3, 5], [6, 5], [6, 7], [4, 7], [4, 8], [1, 8], [1, 6],
        [0, 6], [0, 9], [5, 9], [5, 8], [6, 8], [6, 9], [9, 9], [9, 5],
        [8, 5], [8, 8], [7, 8], [7, 4], [9, 4], [9, 2], [6, 2], [6, 4],
        [5, 4], [5, 1], [8, 1], [8, 0], [4, 0], [4, 2], [2, 2], [2, 0],
        [1, 0], [1, 1],
      ]
  ),
  MasyuPuzzle(8, 8,
      'KrazyDad 8x8 Easy 1-1-1',
      'https://krazydad.com/tablet/masyu/?kind=8x8_d0&volumeNumber=1&bookNumber=1&puzzleNumber=1',
      'Jim Bumgardner',
      'https://krazydad.com/about.php',
      const [
        '........',
        '.O.O....',
        '..OO..OO',
        '.O.O..O.',
        '@.......',
        '.......O',
        '.OOOOO..',
        '........',
      ], const [
        [0, 0], [0, 1], [2, 1], [2, 4], [1, 4], [1, 2], [0, 2], [0, 5],
        [4, 5], [4, 6], [1, 6], [1, 7], [6, 7], [6, 6], [5, 6], [5, 5],
        [7, 5], [7, 4], [5, 4], [5, 3], [7, 3], [7, 2], [5, 2], [5, 1],
        [7, 1], [7, 0], [4, 0], [4, 4], [3, 4], [3, 0],
      ]
  ),
];