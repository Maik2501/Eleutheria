import 'dart:math' as math;

class LetterboxWordSegment {
  const LetterboxWordSegment({
    required this.start,
    required this.end,
    required this.showTrailingHyphen,
  });

  final int start;
  final int end;
  final bool showTrailingHyphen;

  int get length => end - start;
}

List<LetterboxWordSegment> splitWordForLetterbox({
  required String word,
  required int maxCellsPerLine,
}) {
  final length = word.length;
  final lineLimit = math.max(2, maxCellsPerLine);
  if (length <= lineLimit) {
    return [
      LetterboxWordSegment(
        start: 0,
        end: length,
        showTrailingHyphen: false,
      ),
    ];
  }

  final candidates = _hyphenationCandidates(word);
  final segments = <LetterboxWordSegment>[];
  var start = 0;

  while (length - start > lineLimit) {
    final limit = math.min(length - 2, start + lineLimit);
    final split = _bestSplit(candidates, start, limit, length) ?? limit;
    final usesExistingHyphen = split > 0 && word[split - 1] == '-';
    segments.add(
      LetterboxWordSegment(
        start: start,
        end: split,
        showTrailingHyphen: !usesExistingHyphen,
      ),
    );
    start = split;
  }

  segments.add(
    LetterboxWordSegment(
      start: start,
      end: length,
      showTrailingHyphen: false,
    ),
  );
  return segments;
}

int? _bestSplit(
  Map<int, int> candidates,
  int start,
  int limit,
  int length,
) {
  int? best;
  var bestScore = -1 << 30;
  for (final entry in candidates.entries) {
    final position = entry.key;
    if (position <= start + 1 || position > limit || length - position < 2) {
      continue;
    }
    final score = position + entry.value * 4;
    if (score > bestScore) {
      best = position;
      bestScore = score;
    }
  }
  return best;
}

Map<int, int> _hyphenationCandidates(String word) {
  final upper = word.toUpperCase();
  final candidates = <int, int>{};

  void add(int position, [int priority = 0]) {
    if (position < 2 || position > word.length - 2) return;
    candidates.update(
      position,
      (current) => math.max(current, priority),
      ifAbsent: () => priority,
    );
  }

  for (var i = 0; i < word.length - 1; i++) {
    if (word[i] == '-') add(i + 1, 18);
  }

  for (final prefix in _preferredPrefixes) {
    if (upper.startsWith(prefix) && word.length >= prefix.length + 4) {
      add(prefix.length, 8);
    }
  }

  for (final suffix in _preferredSuffixes) {
    if (upper.endsWith(suffix) && word.length >= suffix.length + 4) {
      add(word.length - suffix.length, 7);
    }
  }

  var i = 0;
  while (i < upper.length - 1) {
    if (!_isVowel(upper[i])) {
      i++;
      continue;
    }

    final clusterStart = i + 1;
    if (clusterStart >= upper.length) break;
    if (_isVowel(upper[clusterStart])) {
      add(clusterStart);
      i = clusterStart;
      continue;
    }

    var nextVowel = clusterStart;
    while (nextVowel < upper.length && !_isVowel(upper[nextVowel])) {
      nextVowel++;
    }
    if (nextVowel >= upper.length) break;

    final cluster = upper.substring(clusterStart, nextVowel);
    final breakPosition = _breakBeforeClusterTail(cluster, nextVowel);
    add(breakPosition);
    i = nextVowel;
  }

  return candidates;
}

int _breakBeforeClusterTail(String cluster, int nextVowel) {
  if (cluster.length == 1) return nextVowel - 1;
  if (cluster.endsWith('SCH')) return nextVowel - 3;
  if (cluster.endsWith('CH') ||
      cluster.endsWith('CK') ||
      cluster.endsWith('PH') ||
      cluster.endsWith('TH')) {
    return nextVowel - 2;
  }
  if (cluster.endsWith('ST') || cluster.endsWith('SP')) return nextVowel - 2;
  return nextVowel - 1;
}

bool _isVowel(String char) => 'AEIOUÄÖÜY'.contains(char);

const _preferredPrefixes = [
  'ANTI',
  'AUTO',
  'EXISTENZ',
  'FUNDAMENTAL',
  'INTER',
  'KONTRA',
  'META',
  'NEO',
  'POST',
  'TRANS',
  'ULTRA',
];

const _preferredSuffixes = [
  'ISMUS',
  'ISTISCH',
  'ISTISCHE',
  'LOGIE',
  'LOGISCH',
  'LOGISCHE',
];
