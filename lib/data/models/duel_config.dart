import 'answer_input_style.dart';
import 'difficulty_band.dart';

/// Two ways to play a duel.
enum DuelMode {
  /// Both players see the same question at the same time. First correct
  /// answer wins the points; a wrong answer locks you out of this question
  /// (the other player can still attempt).
  race('Race', 'Erste richtige Antwort gewinnt'),

  /// Both players answer the same questions but independently. Total score
  /// at the end of the session decides.
  parallel('Parallel', 'Beide spielen unabhängig, Summe entscheidet');

  const DuelMode(this.label, this.subtitle);
  final String label;
  final String subtitle;

  String get serverKey => name;

  static DuelMode fromKey(String? key) =>
      values.firstWhere((v) => v.name == key, orElse: () => race);
}

/// Whole-session configuration that the host picks in the lobby and the
/// guest reads from the duel row.
class DuelConfig {
  const DuelConfig({
    required this.mode,
    required this.timeLimitSeconds,
    required this.livesPerPlayer,
    required this.inputStyle,
    required this.difficultyBand,
    this.questionCount = 100,
  });

  final DuelMode mode;

  /// `null` = unlimited.
  final int? timeLimitSeconds;

  /// `null` = unlimited.
  final int? livesPerPlayer;

  final AnswerInputStyle inputStyle;
  final DifficultyBand difficultyBand;

  /// Upper bound for the seeded question pool. Real number played is
  /// driven by time/lives, this is just defensive headroom.
  final int questionCount;

  // ─── Convenience: preset configs that the lobby UI uses ───

  /// Standard beim Öffnen der Lobby (solange nichts gespeichert ist):
  /// Race, 3 Minuten, Leben ohne Limit.
  static const standard = DuelConfig(
    mode: DuelMode.race,
    timeLimitSeconds: 180,
    livesPerPlayer: null,
    inputStyle: AnswerInputStyle.multipleChoice,
    difficultyBand: DifficultyBand.salon,
  );

  static const oneMinute = DuelConfig(
    mode: DuelMode.race,
    timeLimitSeconds: 60,
    livesPerPlayer: 3,
    inputStyle: AnswerInputStyle.multipleChoice,
    difficultyBand: DifficultyBand.salon,
  );
  static const threeMinutes = DuelConfig(
    mode: DuelMode.race,
    timeLimitSeconds: 180,
    livesPerPlayer: 3,
    inputStyle: AnswerInputStyle.multipleChoice,
    difficultyBand: DifficultyBand.salon,
  );
  static const fiveMinutes = DuelConfig(
    mode: DuelMode.race,
    timeLimitSeconds: 300,
    livesPerPlayer: 3,
    inputStyle: AnswerInputStyle.multipleChoice,
    difficultyBand: DifficultyBand.salon,
  );

  DuelConfig copyWith({
    DuelMode? mode,
    int? timeLimitSeconds,
    bool clearTimeLimit = false,
    int? livesPerPlayer,
    bool clearLives = false,
    AnswerInputStyle? inputStyle,
    DifficultyBand? difficultyBand,
    int? questionCount,
  }) =>
      DuelConfig(
        mode: mode ?? this.mode,
        timeLimitSeconds:
            clearTimeLimit ? null : (timeLimitSeconds ?? this.timeLimitSeconds),
        livesPerPlayer:
            clearLives ? null : (livesPerPlayer ?? this.livesPerPlayer),
        inputStyle: inputStyle ?? this.inputStyle,
        difficultyBand: difficultyBand ?? this.difficultyBand,
        questionCount: questionCount ?? this.questionCount,
      );

  /// JSON-Roundtrip für die lokale Persistenz der zuletzt verwendeten
  /// Lobby-Einstellungen (siehe DuelConfigStore).
  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'time_limit_seconds': timeLimitSeconds,
        'lives_per_player': livesPerPlayer,
        'input_style': inputStyle.key,
        'difficulty_band': difficultyBand.name,
        'question_count': questionCount,
      };

  static DuelConfig? tryFromJson(Map<String, dynamic> json) {
    try {
      return DuelConfig(
        mode: DuelMode.fromKey(json['mode'] as String?),
        timeLimitSeconds: (json['time_limit_seconds'] as num?)?.toInt(),
        livesPerPlayer: (json['lives_per_player'] as num?)?.toInt(),
        inputStyle: AnswerInputStyle.fromKey(json['input_style'] as String?),
        difficultyBand: DifficultyBand.values.firstWhere(
          (b) => b.name == json['difficulty_band'],
          orElse: () => DifficultyBand.salon,
        ),
        questionCount: (json['question_count'] as num?)?.toInt() ?? 100,
      );
    } catch (_) {
      return null;
    }
  }

  String get timeLabel {
    final s = timeLimitSeconds;
    if (s == null) return '∞';
    if (s % 60 == 0) return '${s ~/ 60} min';
    return '${s}s';
  }

  String get livesLabel => livesPerPlayer == null ? '∞' : '$livesPerPlayer';
}
