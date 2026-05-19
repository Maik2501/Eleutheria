import 'answer_input_style.dart';

/// Local player profile — no auth required for solo play.
/// Persisted via SharedPreferences (see `ProfileRepository`).
class PlayerProfile {
  PlayerProfile({
    required this.id,
    required this.displayName,
    required this.avatarSeal,
    required this.xp,
    required this.streakDays,
    required this.lastPlayedDate,
    required this.totalGamesPlayed,
    required this.totalCorrect,
    required this.bestSuddenDeath,
    required this.flawlessClassicCount,
    required this.fastCorrectAnswers,
    required this.duelsWon,
    required this.currentDuelStreak,
    required this.bestDuelStreak,
    required this.nightSessionsCount,
    required this.answeredEraKeys,
    required this.unlockedAchievements,
    required this.bookmarkedQuoteIds,
    required this.preferredCategories,
    required this.preferredDifficulty,
    required this.locale,
    required this.themeMode,
    required this.soundsEnabled,
    required this.hapticsEnabled,
    required this.jokerAvailability,
    required this.preferredInputStyle,
  });

  factory PlayerProfile.fresh({
    required String id,
    required String displayName,
  }) =>
      PlayerProfile(
        id: id,
        displayName: displayName,
        avatarSeal: 'Σ',
        xp: 0,
        streakDays: 0,
        lastPlayedDate: null,
        totalGamesPlayed: 0,
        totalCorrect: 0,
        bestSuddenDeath: 0,
        flawlessClassicCount: 0,
        fastCorrectAnswers: 0,
        duelsWon: 0,
        currentDuelStreak: 0,
        bestDuelStreak: 0,
        nightSessionsCount: 0,
        answeredEraKeys: const {},
        unlockedAchievements: const {},
        bookmarkedQuoteIds: const {},
        preferredCategories: const {},
        preferredDifficulty: const (1, 5),
        locale: 'de',
        themeMode: 'system',
        soundsEnabled: false,
        hapticsEnabled: true,
        jokerAvailability: JokerAvailability.always,
        preferredInputStyle: AnswerInputStyle.multipleChoice,
      );

  final String id;
  String displayName;
  String avatarSeal;
  int xp;
  int streakDays;
  DateTime? lastPlayedDate;
  int totalGamesPlayed;
  int totalCorrect;
  int bestSuddenDeath;

  /// How many classic games the player has finished without a single mistake.
  int flawlessClassicCount;

  /// Cumulative count of correct answers given in under three seconds.
  int fastCorrectAnswers;

  /// Cumulative duel wins.
  int duelsWon;

  /// Live counter — consecutive duel wins, reset to 0 on a loss.
  int currentDuelStreak;

  /// Longest streak of consecutive duel wins ever reached.
  int bestDuelStreak;

  /// Sessions played between 0:00 and 4:00 local time.
  int nightSessionsCount;

  /// Era keys (matching `Era.name`) the player has answered at least one
  /// question correctly in. Persisted as strings so the model stays free of
  /// imports beyond primitives.
  Set<String> answeredEraKeys;

  Set<String> unlockedAchievements;
  Set<String> bookmarkedQuoteIds;
  Set<String> preferredCategories;
  (int, int) preferredDifficulty;

  String locale;
  String themeMode; // 'light' | 'dark' | 'system'
  bool soundsEnabled;
  bool hapticsEnabled;
  JokerAvailability jokerAvailability;
  AnswerInputStyle preferredInputStyle;

  /// XP curve: each level requires 250 + 100 × level XP.
  int get level {
    var lvl = 1;
    var remaining = xp;
    while (remaining >= 250 + 100 * lvl) {
      remaining -= 250 + 100 * lvl;
      lvl++;
    }
    return lvl;
  }

  int get xpIntoCurrentLevel {
    var lvl = 1;
    var remaining = xp;
    while (remaining >= 250 + 100 * lvl) {
      remaining -= 250 + 100 * lvl;
      lvl++;
    }
    return remaining;
  }

  int get xpForNextLevel => 250 + 100 * level;

  String get rankTitle => switch (level) {
        < 3 => 'Lehrling',
        < 6 => 'Schüler',
        < 10 => 'Akademiker',
        < 15 => 'Gelehrter',
        < 22 => 'Magister',
        < 30 => 'Doktor',
        < 40 => 'Professor',
        _ => 'Weiser',
      };
}

enum JokerAvailability {
  disabled('off', 'Aus', 0),
  one('one', '1 Joker', 1),
  three('three', '3 Joker', 3),
  always('always', 'Immer', null);

  const JokerAvailability(this.key, this.label, this.sessionLimit);

  final String key;
  final String label;
  final int? sessionLimit;

  static JokerAvailability fromKey(String? key) =>
      JokerAvailability.values.firstWhere(
        (value) => value.key == key,
        orElse: () => JokerAvailability.always,
      );
}
