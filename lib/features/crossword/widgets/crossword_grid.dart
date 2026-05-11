import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../crossword_controller.dart';
import '../models/crossword_puzzle.dart';

/// Renders the crossword grid. Cells are square, scaled to fit the available
/// width. Active word highlighted in gold; active cell highlighted in burgundy.
class CrosswordGrid extends StatelessWidget {
  const CrosswordGrid({
    super.key,
    required this.state,
    required this.onTapCell,
    this.maxSide = 480,
    this.showLetterFeedback = false,
  });

  final CrosswordState state;
  final void Function(int row, int col) onTapCell;
  final double maxSide;
  final bool showLetterFeedback;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final puzzle = state.puzzle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : maxSide;
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : maxWidth;
        const frameWidth = 1.4;
        final maxSize = math.min(math.min(maxWidth, maxHeight), maxSide);
        final contentCap = math.max(0.0, maxSize - (frameWidth * 2));
        final cellSize = (contentCap / puzzle.gridCols).floorToDouble();
        final gridW = cellSize * puzzle.gridCols;
        final gridH = cellSize * puzzle.gridRows;
        final frameW = gridW + (frameWidth * 2);
        final frameH = gridH + (frameWidth * 2);

        // Compute the active-word cells for highlighting.
        final activeCells = _activeWordCells(puzzle, state);

        // Numbering map: cell -> number (only at word starts).
        final numbersByCell = <(int, int), int>{
          for (final nw in puzzle.numberedWords)
            (nw.word.row, nw.word.col): nw.number,
        };

        return SizedBox(
          width: frameW,
          height: frameH,
          child: Container(
            decoration: BoxDecoration(
              color: palette.parchment,
              border: Border.all(color: palette.ink, width: frameWidth),
            ),
            child: Column(
              children: [
                for (var r = 0; r < puzzle.gridRows; r++)
                  Row(
                    children: [
                      for (var c = 0; c < puzzle.gridCols; c++)
                        _Cell(
                          size: cellSize,
                          state: state,
                          row: r,
                          col: c,
                          number: numbersByCell[(r, c)],
                          isActive: activeCells.contains((r, c)),
                          isFocus: r == state.focusRow && c == state.focusCol,
                          showLetterFeedback: showLetterFeedback,
                          onTap: () => onTapCell(r, c),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Set<(int, int)> _activeWordCells(
    CrosswordPuzzle puzzle,
    CrosswordState state,
  ) {
    final cell = puzzle.grid[state.focusRow][state.focusCol];
    if (cell == null) return const {};
    final word = cell.words.firstWhere(
      (w) => w.direction == state.focusDirection,
      orElse: () => cell.words.first,
    );
    return word.cells().toSet();
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.size,
    required this.state,
    required this.row,
    required this.col,
    required this.number,
    required this.isActive,
    required this.isFocus,
    required this.showLetterFeedback,
    required this.onTap,
  });

  final double size;
  final CrosswordState state;
  final int row;
  final int col;
  final int? number;
  final bool isActive;
  final bool isFocus;
  final bool showLetterFeedback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cell = state.puzzle.grid[row][col];

    if (cell == null) {
      return Semantics(
        label: 'Sperrfeld, Zeile ${row + 1}, Spalte ${col + 1}',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.92),
            border: Border.all(
              color: palette.ink.withValues(alpha: 0.4),
              width: 0.4,
            ),
          ),
        ),
      );
    }

    final typed = state.typed[row][col];
    final correct = cell.letter;
    final isCorrect = typed.toUpperCase() == correct.toUpperCase();
    final hasInput = typed.isNotEmpty;
    final showFeedback = showLetterFeedback &&
        hasInput &&
        cell.words.any((word) => _isWordFilled(word, state.typed));

    final Color bg;
    if (showFeedback) {
      bg = (isCorrect ? palette.correct : palette.incorrect).withValues(
        alpha: isCorrect ? 0.16 : 0.13,
      );
    } else if (isFocus) {
      bg = palette.burgundy.withValues(alpha: 0.18);
    } else if (isActive) {
      bg = palette.gold.withValues(alpha: 0.22);
    } else {
      bg = palette.page;
    }

    final directions = cell.words
        .map(
          (w) =>
              w.direction == WordDirection.across ? 'waagerecht' : 'senkrecht',
        )
        .join(' und ');
    final textColor = showFeedback
        ? (isCorrect ? palette.correct : palette.incorrect)
        : hasInput
            ? (isCorrect && state.completed ? palette.correct : palette.ink)
            : palette.ink;

    return Semantics(
      button: true,
      selected: isFocus,
      label:
          'Zeile ${row + 1}, Spalte ${col + 1}, ${typed.isEmpty ? 'leer' : typed.toUpperCase()}, $directions',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: palette.ink.withValues(alpha: 0.55),
              width: 0.5,
            ),
          ),
          child: Stack(
            children: [
              if (number != null)
                Positioned(
                  left: 3,
                  top: 1,
                  child: Text(
                    '$number',
                    style: AppTypography.sans(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w700,
                      color: palette.inkMuted,
                      height: 1.0,
                    ),
                  ),
                ),
              Center(
                child: Text(
                  typed.toUpperCase(),
                  style: AppTypography.serif(
                    fontSize: size * 0.55,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isWordFilled(CrosswordWord word, List<List<String>> typed) {
    for (final (r, c) in word.cells()) {
      if (typed[r][c].trim().isEmpty) return false;
    }
    return true;
  }
}
