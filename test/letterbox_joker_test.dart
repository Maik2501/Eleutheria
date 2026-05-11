import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:philosophie_quiz/features/letterbox/letterbox_joker.dart';

void main() {
  test('reveals half of letters rounded down and caps at three', () {
    expect(letterboxFiftyFiftyRevealCount('KANT'), 2);
    expect(letterboxFiftyFiftyRevealCount('VERNUNFT'), 3);
  });

  test('ignores spaces and hyphens as reveal candidates', () {
    expect(letterboxFiftyFiftyRevealCount('WU-WEI'), 2);
    expect(letterboxFiftyFiftyRevealCount('in mir'), 2);
  });

  test('picks deterministic randomized indices when a random seed is supplied',
      () {
    final first = pickLetterboxFiftyFiftyIndices(
      'VERNUNFT',
      random: math.Random(7),
    );
    final second = pickLetterboxFiftyFiftyIndices(
      'VERNUNFT',
      random: math.Random(7),
    );

    expect(first, second);
    expect(first.length, 3);
  });

  test('typing limit shrinks by revealed letter count', () {
    expect(letterboxTypingLimit('KANT', {1, 3}), 2);
    expect(letterboxTypingLimit('WU-WEI', {0, 3}), 3);
  });

  test('merges typed input with revealed letters', () {
    expect(mergeLetterboxReveals('KANT', 'KN', {1, 3}), 'KANT');
    expect(mergeLetterboxReveals('WU-WEI', 'WEI', {0, 1}), 'WU-WEI');
  });
}
