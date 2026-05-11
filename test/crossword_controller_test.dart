import 'package:flutter_test/flutter_test.dart';
import 'package:philosophie_quiz/features/crossword/crossword_controller.dart';
import 'package:philosophie_quiz/features/crossword/models/crossword_puzzle.dart';

void main() {
  test('focusCell snaps to single direction and toggles repeated intersections',
      () {
    final controller = CrosswordController(_testPuzzle);

    expect(controller.state.focusDirection, WordDirection.across);

    controller.focusCell(1, 0);
    expect(controller.state.focusDirection, WordDirection.down);

    controller.focusCell(0, 0);
    expect(controller.state.focusDirection, WordDirection.down);

    controller.focusCell(0, 0);
    expect(controller.state.focusDirection, WordDirection.across);
  });
}

final _testPuzzle = CrosswordPuzzle(
  id: 'tap_behavior',
  title: 'Tap behavior',
  theme: 'Test',
  gridRows: 2,
  gridCols: 3,
  words: const [
    CrosswordWord(
      id: 'across',
      answer: 'ABC',
      clue: 'Across',
      row: 0,
      col: 0,
      direction: WordDirection.across,
    ),
    CrosswordWord(
      id: 'down',
      answer: 'AD',
      clue: 'Down',
      row: 0,
      col: 0,
      direction: WordDirection.down,
    ),
  ],
);
