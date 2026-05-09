import 'crossword_puzzle.dart';

/// First crossword puzzle. 9×9 grid, 5 crossing answers.
///
/// Layout (verified by hand — see grid below):
/// ```
///       0 1 2 3 4 5 6 7 8
///   0   ·  ·  ·  ·  N  ·  ·  ·  ·
///   1   ·  ·  ·  ·  I  ·  ·  ·  ·
///   2   ·  ·  M  ·  E  ·  ·  ·  ·
///   3   ·  K  A  N  T  ·  ·  ·  ·
///   4   ·  ·  R  ·  Z  ·  ·  H  ·
///   5   ·  ·  X  ·  S  ·  ·  U  ·
///   6   ·  ·  ·  ·  C  ·  ·  M  ·
///   7   ·  ·  ·  ·  H  E  G  E  L
///   8   ·  ·  ·  ·  E  ·  ·  ·  ·
/// ```
/// Crossings:
///  - KANT[3]=T  ↔ NIETZSCHE[3]=T  at (3,4)
///  - KANT[1]=A  ↔ MARX[1]=A       at (3,2)
///  - HEGEL[0]=H ↔ NIETZSCHE[7]=H  at (7,4)
///  - HEGEL[3]=E ↔ HUME[3]=E       at (7,7)
final puzzleAuftaktDerNeuzeit = CrosswordPuzzle(
  id: 'auftakt_der_neuzeit',
  title: 'Auftakt der Neuzeit',
  theme: 'Aufklärung & 19. Jahrhundert',
  gridRows: 9,
  gridCols: 9,
  words: [
    CrosswordWord(
      id: 'nietzsche_d',
      answer: 'NIETZSCHE',
      clue: 'Diagnostiker des Nihilismus, Vordenker des Übermenschen.',
      row: 0,
      col: 4,
      direction: WordDirection.down,
      attribution: 'Also sprach Zarathustra',
      explanation: 'Sein „Werde, der du bist" prägte das 20. Jahrhundert.',
    ),
    CrosswordWord(
      id: 'marx_d',
      answer: 'MARX',
      clue: 'Stellte Hegels Idealismus „auf die Füße".',
      row: 2,
      col: 2,
      direction: WordDirection.down,
      attribution: 'Das Kapital',
      explanation: 'Begründer des historischen Materialismus.',
    ),
    CrosswordWord(
      id: 'kant_a',
      answer: 'KANT',
      clue: 'Königsberger, der die reine Vernunft kritisierte.',
      row: 3,
      col: 1,
      direction: WordDirection.across,
      attribution: 'Kritik der reinen Vernunft, 1781',
      explanation: 'Begründer der Transzendentalphilosophie.',
    ),
    CrosswordWord(
      id: 'hume_d',
      answer: 'HUME',
      clue: 'Schottischer Skeptiker — kritisierte die Kausalität.',
      row: 4,
      col: 7,
      direction: WordDirection.down,
      explanation:
          'Empirist; weckte Kant aus dessen „dogmatischem Schlummer".',
    ),
    CrosswordWord(
      id: 'hegel_a',
      answer: 'HEGEL',
      clue: 'Vater der Dialektik des absoluten Geistes.',
      row: 7,
      col: 4,
      direction: WordDirection.across,
      attribution: 'Phänomenologie des Geistes, 1807',
      explanation: 'Denker der dialektischen Bewegung des Geistes.',
    ),
  ],
);

final List<CrosswordPuzzle> kCrosswordPuzzles = [puzzleAuftaktDerNeuzeit];
