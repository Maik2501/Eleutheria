/// Local player profile — no auth required for solo play.
/// Persisted in Hive.
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
    required this.unlockedAchievements,
    required this.bookmarkedQuoteIds,
    required this.preferredCategories,
    required this.preferredDifficulty,
    required this.locale,
    required this.themeMode,
    required this.soundsEnabled,
    required this.hapticsEnabled,
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
        unlockedAchievements: const {},
        bookmarkedQuoteIds: const {},
        preferredCategories: const {},
        preferredDifficulty: const (1, 5),
        locale: 'de',
        themeMode: 'system',
        soundsEnabled: false,
        hapticsEnabled: true,
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

  Set<String> unlockedAchievements;
  Set<String> bookmarkedQuoteIds;
  Set<String> preferredCategories;
  (int, int) preferredDifficulty;

  String locale;
  String themeMode; // 'light' | 'dark' | 'system'
  bool soundsEnabled;
  bool hapticsEnabled;

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
