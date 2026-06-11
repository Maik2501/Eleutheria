import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/crossword_puzzle.dart';
import '../../core/haptics.dart';

/// Per-puzzle UI state: typed grid, focused cell, focus direction, solved
/// words.
class CrosswordState {
  CrosswordState({
    required this.puzzle,
    required this.typed,
    required this.focusRow,
    required this.focusCol,
    required this.focusDirection,
    required this.completed,
  });

  final CrosswordPuzzle puzzle;
  final List<List<String>> typed;
  final int focusRow;
  final int focusCol;
  final WordDirection focusDirection;
  final bool completed;

  CrosswordState copyWith({
    List<List<String>>? typed,
    int? focusRow,
    int? focusCol,
    WordDirection? focusDirection,
    bool? completed,
  }) =>
      CrosswordState(
        puzzle: puzzle,
        typed: typed ?? this.typed,
        focusRow: focusRow ?? this.focusRow,
        focusCol: focusCol ?? this.focusCol,
        focusDirection: focusDirection ?? this.focusDirection,
        completed: completed ?? this.completed,
      );
}

final crosswordProvider = StateNotifierProvider.autoDispose
    .family<CrosswordController, CrosswordState, CrosswordPuzzle>(
  (ref, puzzle) => CrosswordController(puzzle),
);

class CrosswordController extends StateNotifier<CrosswordState> {
  CrosswordController(CrosswordPuzzle puzzle) : super(_initial(puzzle));

  static CrosswordState _initial(CrosswordPuzzle puzzle) {
    final typed = List.generate(
      puzzle.gridRows,
      (_) => List<String>.filled(puzzle.gridCols, ''),
    );
    final first = puzzle.numberedWords.first.word;
    return CrosswordState(
      puzzle: puzzle,
      typed: typed,
      focusRow: first.row,
      focusCol: first.col,
      focusDirection: first.direction,
      completed: false,
    );
  }

  // ─── Navigation ───
  void focusCell(int row, int col, {WordDirection? direction}) {
    final cell = state.puzzle.grid[row][col];
    if (cell == null) return;

    final directions = {for (final word in cell.words) word.direction};
    final isSameCell = state.focusRow == row && state.focusCol == col;
    var dir = direction;
    if (dir == null) {
      if (directions.length == 1) {
        dir = directions.single;
      } else if (isSameCell) {
        dir = state.focusDirection == WordDirection.across
            ? WordDirection.down
            : WordDirection.across;
      } else if (directions.contains(state.focusDirection)) {
        dir = state.focusDirection;
      } else {
        dir = cell.words.first.direction;
      }
    } else if (!directions.contains(dir)) {
      dir = cell.words.first.direction;
    }

    state = state.copyWith(focusRow: row, focusCol: col, focusDirection: dir);
  }

  void toggleDirection() {
    final cell = state.puzzle.grid[state.focusRow][state.focusCol];
    if (cell == null) return;
    final has = {for (final w in cell.words) w.direction};
    if (has.length < 2) return;
    state = state.copyWith(
      focusDirection: state.focusDirection == WordDirection.across
          ? WordDirection.down
          : WordDirection.across,
    );
  }

  /// Jump to a numbered word (used by clue list taps).
  void focusWord(CrosswordWord w) {
    state = state.copyWith(
      focusRow: w.row,
      focusCol: w.col,
      focusDirection: w.direction,
    );
  }

  /// Move focus forward within the active word, or to the next word
  /// when at the end.
  void _advance() {
    final w = _activeWord();
    if (w == null) return;
    final cells = w.cells().toList();
    final idx = cells.indexWhere(
      (c) => c.$1 == state.focusRow && c.$2 == state.focusCol,
    );
    if (idx < cells.length - 1) {
      final next = cells[idx + 1];
      state = state.copyWith(focusRow: next.$1, focusCol: next.$2);
    } else {
      _focusNextWord();
    }
  }

  void _retreat() {
    final w = _activeWord();
    if (w == null) return;
    final cells = w.cells().toList();
    final idx = cells.indexWhere(
      (c) => c.$1 == state.focusRow && c.$2 == state.focusCol,
    );
    if (idx > 0) {
      final prev = cells[idx - 1];
      state = state.copyWith(focusRow: prev.$1, focusCol: prev.$2);
    }
  }

  void _focusNextWord() {
    final ordered = state.puzzle.numberedWords;
    final current = _activeWord();
    final idx = ordered.indexWhere((nw) => nw.word == current);
    final next = ordered[(idx + 1) % ordered.length].word;
    focusWord(next);
  }

  void focusPrevWord() {
    final ordered = state.puzzle.numberedWords;
    final current = _activeWord();
    final idx = ordered.indexWhere((nw) => nw.word == current);
    final prev = ordered[(idx - 1 + ordered.length) % ordered.length].word;
    focusWord(prev);
  }

  void focusNextWord() => _focusNextWord();

  CrosswordWord? _activeWord() {
    final cell = state.puzzle.grid[state.focusRow][state.focusCol];
    if (cell == null) return null;
    return cell.words.firstWhere(
      (w) => w.direction == state.focusDirection,
      orElse: () => cell.words.first,
    );
  }

  CrosswordWord? get activeWord => _activeWord();

  // ─── Input ───
  void typeLetter(String letter) {
    if (state.completed) return;
    final upper = letter.toUpperCase();
    if (upper.isEmpty || !RegExp(r'[A-ZÄÖÜß]').hasMatch(upper)) return;

    final newTyped = _cloneGrid(state.typed);
    newTyped[state.focusRow][state.focusCol] = upper;

    final solved = state.puzzle.isSolved(newTyped);
    state = state.copyWith(typed: newTyped, completed: solved);

    Haptics.selection();
    if (!solved) _advance();
  }

  void backspace() {
    if (state.completed) return;
    final newTyped = _cloneGrid(state.typed);
    if (newTyped[state.focusRow][state.focusCol].isNotEmpty) {
      newTyped[state.focusRow][state.focusCol] = '';
      state = state.copyWith(typed: newTyped);
    } else {
      _retreat();
      final newTyped2 = _cloneGrid(state.typed);
      newTyped2[state.focusRow][state.focusCol] = '';
      state = state.copyWith(typed: newTyped2);
    }
    Haptics.light();
  }

  /// Reveal the active word — fills in the correct letters.
  /// Triggers haptic; doesn't count as solved (still useful for learning).
  void revealActiveWord() {
    final w = _activeWord();
    if (w == null) return;
    _fillWord(w);
    Haptics.medium();
  }

  void _fillWord(CrosswordWord w) {
    final newTyped = _cloneGrid(state.typed);
    var i = 0;
    for (final (r, c) in w.cells()) {
      newTyped[r][c] = w.answer[i].toUpperCase();
      i++;
    }
    final solved = state.puzzle.isSolved(newTyped);
    state = state.copyWith(typed: newTyped, completed: solved);
  }

  static List<List<String>> _cloneGrid(List<List<String>> g) => [
        for (final row in g) [...row],
      ];
}
