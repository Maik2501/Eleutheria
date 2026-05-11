import 'dart:math' as math;

import 'answer_normalization.dart';

int letterboxFiftyFiftyRevealCount(String target) {
  final candidateCount = _letterIndices(target).length;
  return math.min(3, candidateCount ~/ 2);
}

int letterboxTypingLimit(String target, Set<int> revealedIndices) {
  final normalized = normalizeForLetterbox(target).replaceAll(' ', '');
  var count = 0;
  for (var i = 0; i < normalized.length; i++) {
    if (!isLetterboxTypedCharacter(normalized[i])) continue;
    if (!revealedIndices.contains(i)) count++;
  }
  return count;
}

String mergeLetterboxReveals(
  String target,
  String typed,
  Set<int> revealedIndices,
) {
  final normalized = normalizeForLetterbox(target).replaceAll(' ', '');
  final buffer = StringBuffer();
  var typedIndex = 0;

  for (var i = 0; i < normalized.length; i++) {
    if (!isLetterboxTypedCharacter(normalized[i])) {
      buffer.write(normalized[i]);
    } else if (revealedIndices.contains(i)) {
      buffer.write(normalized[i]);
    } else if (typedIndex < typed.length) {
      buffer.write(typed[typedIndex]);
      typedIndex++;
    } else {
      break;
    }
  }

  return buffer.toString();
}

bool isLetterboxTypedCharacter(String char) =>
    RegExp(r'[A-Za-zÄÖÜäöüß0-9]').hasMatch(char);

Set<int> pickLetterboxFiftyFiftyIndices(
  String target, {
  math.Random? random,
}) {
  final count = letterboxFiftyFiftyRevealCount(target);
  if (count <= 0) return const {};

  final indices = _letterIndices(target)..shuffle(random ?? math.Random());
  return indices.take(count).toSet();
}

List<int> _letterIndices(String target) {
  final normalized = normalizeForLetterbox(target);
  final indices = <int>[];
  var visibleIndex = 0;

  for (var i = 0; i < normalized.length; i++) {
    final char = normalized[i];
    if (char == ' ') continue;
    if (_isLetter(char)) indices.add(visibleIndex);
    visibleIndex++;
  }

  return indices;
}

bool _isLetter(String char) => RegExp(r'[A-Za-zÄÖÜäöüß]').hasMatch(char);
