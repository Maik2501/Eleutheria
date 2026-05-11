import 'question.dart';

/// One run of the quiz — solo or VS.
class GameSession {
  GameSession({
    required this.id,
    required this.mode,
    required this.questions,
    required this.startedAt,
    this.categories = const {},
    this.difficultyMin = 1,
    this.difficultyMax = 5,
    this.usedPowerUps = const [],
    List<AnswerRecord>? answers,
  }) : answers = answers ?? <AnswerRecord>[];

  final String id;
  final GameMode mode;
  final List<Question> questions;
  final DateTime startedAt;

  /// Categories the player chose for this session (empty = all).
  final Set<QuestionCategory> categories;
  final int difficultyMin;
  final int difficultyMax;

  /// Records, one per answered question.
  final List<AnswerRecord> answers;

  /// PowerUps consumed in this session.
  final List<PowerUpKind> usedPowerUps;

  /// Index of the question currently being *displayed*. Advanced by the
  /// controller's `next()` — not by `submit()`, so the answered question stays
  /// on screen while the reveal panel is open.
  int currentIndex = 0;

  bool get isFinished => currentIndex >= questions.length;
  Question? get currentQuestion =>
      isFinished ? null : questions[currentIndex];

  int get correctCount => answers.where((a) => a.wasCorrect).length;
  int get totalScore =>
      answers.fold<int>(0, (sum, a) => sum + a.points);

  Duration get totalTimeTaken => answers.fold<Duration>(
        Duration.zero,
        (sum, a) => sum + a.timeTaken,
      );
}

enum GameMode {
  quizRush('Quiz-Rush', 'Bestzeit, Serien und Leben'),
  classic('Klassisch', 'Zehn Fragen, gemischte Kategorien'),
  suddenDeath('Sudden Death', 'Bis zum ersten Fehler'),
  daily('Tägliche Frage', 'Fünf Fragen, derselbe Pool für alle'),
  vsOnline('Duell', 'Live gegen einen Mitspieler'),
  practice('Studierkammer', 'Ohne Wertung — mit Erklärungen'),
  category('Sammlung', 'Eine bestimmte Kategorie üben');

  const GameMode(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

class AnswerRecord {
  const AnswerRecord({
    required this.questionId,
    required this.selectedIndex,
    required this.wasCorrect,
    required this.timeTaken,
    required this.points,
    this.usedPowerUp,
  });

  final String questionId;

  /// -1 if the question was skipped or timed out.
  final int selectedIndex;
  final bool wasCorrect;
  final Duration timeTaken;
  final int points;
  final PowerUpKind? usedPowerUp;
}

enum PowerUpKind {
  fiftyFifty('50 / 50', 'Entferne zwei falsche Antworten'),
  hint('Hinweis', 'Zeigt die Epoche oder Schule'),
  freezeTime('Zeit anhalten', 'Drei Sekunden Pause'),
  secondChance('Zweite Chance', 'Eine erneute Wahl');

  const PowerUpKind(this.label, this.description);
  final String label;
  final String description;
}
