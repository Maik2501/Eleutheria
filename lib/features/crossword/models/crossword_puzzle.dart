/// Static, hand-built crossword puzzles for the "Echtes Kreuzworträtsel"
/// mode. Generation happens at design time — not at runtime — so the layouts
/// stay elegant.
library;

import '../../letterbox/answer_normalization.dart';

enum WordDirection { across, down }

/// One placed word in a crossword grid.
class CrosswordWord {
  const CrosswordWord({
    required this.id,
    required this.answer,
    required this.clue,
    required this.row,
    required this.col,
    required this.direction,
    this.attribution,
    this.explanation,
  });

  /// Stable id (e.g., '1A' / '7D'). Numbering is computed by the puzzle.
  final String id;

  /// Canonical answer — letters only, no spaces. Stored uppercase.
  final String answer;

  /// The clue text (already-formatted, German).
  final String clue;

  /// Top-left cell of this word, 0-based.
  final int row;
  final int col;

  final WordDirection direction;

  /// Optional attribution shown after solve.
  final String? attribution;

  /// 1–2 sentences shown when the word resolves green.
  final String? explanation;

  /// Iterates the (row, col) cells covered by this word.
  Iterable<(int, int)> cells() sync* {
    for (var i = 0; i < answer.length; i++) {
      yield direction == WordDirection.across ? (row, col + i) : (row + i, col);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'answer': answer,
        'clue': clue,
        'row': row,
        'col': col,
        'direction': direction.name,
        'attribution': attribution,
        'explanation': explanation,
      };

  static CrosswordWord? tryFromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final answer = json['answer'] as String?;
      final clue = json['clue'] as String?;
      final row = (json['row'] as num?)?.toInt();
      final col = (json['col'] as num?)?.toInt();
      final directionName = json['direction'] as String?;
      if (id == null ||
          answer == null ||
          clue == null ||
          row == null ||
          col == null ||
          directionName == null) {
        return null;
      }
      final direction = WordDirection.values
          .where((d) => d.name == directionName)
          .firstOrNull;
      if (direction == null) return null;
      return CrosswordWord(
        id: id,
        answer: answer,
        clue: clue,
        row: row,
        col: col,
        direction: direction,
        attribution: json['attribution'] as String?,
        explanation: json['explanation'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// A whole puzzle.
class CrosswordPuzzle {
  CrosswordPuzzle({
    required this.id,
    required this.title,
    required this.theme,
    required this.gridRows,
    required this.gridCols,
    required this.words,
    this.difficulty = 'Mittel',
    this.estimatedMinutes = 8,
    this.sourceLabel = 'Eleutheria',
  });

  final String id;
  final String title;
  final String theme;
  final int gridRows;
  final int gridCols;
  final List<CrosswordWord> words;
  final String difficulty;
  final int estimatedMinutes;
  final String sourceLabel;

  /// Lazily computed: which letter belongs in each (row, col), and which
  /// words pass through that cell. Cells with `letter == null` are blocked.
  late final List<List<CrosswordCell?>> grid = _buildGrid();

  /// Sorted word list with display numbers attached, in standard crossword
  /// order (top-to-bottom, left-to-right by start cell).
  late final List<NumberedWord> numberedWords = _numberWords();

  List<List<CrosswordCell?>> _buildGrid() {
    final g = List.generate(
      gridRows,
      (_) => List<CrosswordCell?>.filled(gridCols, null),
    );
    for (final w in words) {
      for (final (i, (r, c)) in w.cells().indexed) {
        final letter = w.answer[i].toUpperCase();
        final existing = g[r][c];
        if (existing == null) {
          g[r][c] = CrosswordCell(letter: letter, words: [w]);
        } else {
          assert(
            existing.letter == letter,
            'Crossword conflict at ($r,$c): "${existing.letter}" vs "$letter" for ${w.id}',
          );
          g[r][c] = CrosswordCell(
            letter: letter,
            words: [...existing.words, w],
          );
        }
      }
    }
    return g;
  }

  List<NumberedWord> _numberWords() {
    final starts = <(int, int), int>{};
    var counter = 1;

    // Order: top-to-bottom, left-to-right. A start cell is one that begins
    // an across or down word, by standard crossword convention.
    for (var r = 0; r < gridRows; r++) {
      for (var c = 0; c < gridCols; c++) {
        if (grid[r][c] == null) continue;
        final startsAcross = words.any(
          (w) =>
              w.direction == WordDirection.across && w.row == r && w.col == c,
        );
        final startsDown = words.any(
          (w) => w.direction == WordDirection.down && w.row == r && w.col == c,
        );
        if (startsAcross || startsDown) {
          starts[(r, c)] = counter++;
        }
      }
    }

    return [
      for (final w in words)
        NumberedWord(
          word: w,
          number: starts[(w.row, w.col)] ?? 0,
        ),
    ]..sort((a, b) {
        if (a.number != b.number) return a.number.compareTo(b.number);
        return a.word.direction.index.compareTo(b.word.direction.index);
      });
  }

  /// True if this typed grid completes the puzzle (every cell filled
  /// with the correct letter).
  bool isSolved(List<List<String>> typed) {
    for (var r = 0; r < gridRows; r++) {
      for (var c = 0; c < gridCols; c++) {
        final cell = grid[r][c];
        if (cell == null) continue;
        if (canonicalize(typed[r][c]) != canonicalize(cell.letter)) {
          return false;
        }
      }
    }
    return true;
  }

  /// True iff the word at [w] is fully and correctly filled.
  bool isWordSolved(CrosswordWord w, List<List<String>> typed) {
    var i = 0;
    for (final (r, c) in w.cells()) {
      if (canonicalize(typed[r][c]) != canonicalize(w.answer[i])) return false;
      i++;
    }
    return true;
  }

  int get playableCellCount {
    var count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell != null) count++;
      }
    }
    return count;
  }

  int filledCellCount(List<List<String>> typed) {
    var count = 0;
    for (var r = 0; r < gridRows; r++) {
      for (var c = 0; c < gridCols; c++) {
        if (grid[r][c] != null && typed[r][c].trim().isNotEmpty) count++;
      }
    }
    return count;
  }

  double progress(List<List<String>> typed) {
    final total = playableCellCount;
    if (total == 0) return 0;
    return filledCellCount(typed) / total;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'theme': theme,
        'grid_rows': gridRows,
        'grid_cols': gridCols,
        'difficulty': difficulty,
        'estimated_minutes': estimatedMinutes,
        'source_label': sourceLabel,
        'words': words.map((w) => w.toJson()).toList(),
      };

  static CrosswordPuzzle? tryFromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final title = json['title'] as String?;
      final theme = json['theme'] as String?;
      final gridRows = (json['grid_rows'] as num?)?.toInt();
      final gridCols = (json['grid_cols'] as num?)?.toInt();
      final wordsRaw = json['words'] as List?;
      if (id == null ||
          title == null ||
          theme == null ||
          gridRows == null ||
          gridCols == null ||
          wordsRaw == null) {
        return null;
      }
      final words = <CrosswordWord>[];
      for (final w in wordsRaw) {
        if (w is! Map) continue;
        final parsed =
            CrosswordWord.tryFromJson(Map<String, dynamic>.from(w));
        if (parsed != null) words.add(parsed);
      }
      if (words.isEmpty) return null;
      return CrosswordPuzzle(
        id: id,
        title: title,
        theme: theme,
        gridRows: gridRows,
        gridCols: gridCols,
        words: words,
        difficulty: (json['difficulty'] as String?) ?? 'Mittel',
        estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 8,
        sourceLabel: (json['source_label'] as String?) ?? 'Eleutheria',
      );
    } catch (_) {
      return null;
    }
  }
}

class CrosswordCell {
  const CrosswordCell({required this.letter, required this.words});

  /// The expected (correct) letter.
  final String letter;

  /// Which words pass through this cell (1 or 2, since we have only across/down).
  final List<CrosswordWord> words;
}

class NumberedWord {
  const NumberedWord({required this.word, required this.number});

  final CrosswordWord word;
  final int number;
}

extension _IndexedIterable<T> on Iterable<T> {
  Iterable<(int, T)> get indexed sync* {
    var i = 0;
    for (final v in this) {
      yield (i, v);
      i++;
    }
  }
}
