import 'package:flutter_test/flutter_test.dart';
import 'package:philosophie_quiz/features/letterbox/letterbox_hyphenation.dart';

void main() {
  test('splits long German words at preferred syllable-like positions', () {
    final segments = splitWordForLetterbox(
      word: 'VERNUNFT',
      maxCellsPerLine: 5,
    );

    expect(_parts('VERNUNFT', segments), ['VER-', 'NUNFT']);
  });

  test('prefers common compound prefixes over rough character chunks', () {
    final segments = splitWordForLetterbox(
      word: 'POSTSTRUKTURALISMUS',
      maxCellsPerLine: 8,
    );

    expect(_parts('POSTSTRUKTURALISMUS', segments).first, 'POST-');
  });

  test('does not add a second visual hyphen after an existing hyphen', () {
    final segments = splitWordForLetterbox(
      word: 'QUINE-DUHEM-THESE',
      maxCellsPerLine: 7,
    );

    expect(segments.first.showTrailingHyphen, isFalse);
    expect(_parts('QUINE-DUHEM-THESE', segments).first, 'QUINE-');
  });
}

List<String> _parts(String word, List<LetterboxWordSegment> segments) => [
      for (final segment in segments)
        '${word.substring(segment.start, segment.end)}${segment.showTrailingHyphen ? '-' : ''}',
    ];
