import 'philosopher.dart';
import 'player_profile.dart';

/// Immutable snapshot of every counter the achievement engine cares about.
///
/// Built once per achievement-evaluation pass. Keep this in sync with the
/// progress functions in `achievement.dart` — every counter referenced from
/// there must have a field here, otherwise the achievement can never trigger.
class PlayerStats {
  const PlayerStats({
    required this.totalGamesPlayed,
    required this.totalCorrect,
    required this.streakDays,
    required this.bestSuddenDeath,
    required this.flawlessClassicCount,
    required this.fastCorrectAnswers,
    required this.duelsWon,
    required this.bestDuelStreak,
    required this.nightSessionsCount,
    required this.answeredEras,
    required this.bookmarkCount,
  });

  final int totalGamesPlayed;
  final int totalCorrect;
  final int streakDays;
  final int bestSuddenDeath;
  final int flawlessClassicCount;
  final int fastCorrectAnswers;
  final int duelsWon;
  final int bestDuelStreak;
  final int nightSessionsCount;
  final Set<Era> answeredEras;
  final int bookmarkCount;

  /// Read every counter directly from the persisted profile.
  factory PlayerStats.fromProfile(PlayerProfile p) => PlayerStats(
        totalGamesPlayed: p.totalGamesPlayed,
        totalCorrect: p.totalCorrect,
        streakDays: p.streakDays,
        bestSuddenDeath: p.bestSuddenDeath,
        flawlessClassicCount: p.flawlessClassicCount,
        fastCorrectAnswers: p.fastCorrectAnswers,
        duelsWon: p.duelsWon,
        bestDuelStreak: p.bestDuelStreak,
        nightSessionsCount: p.nightSessionsCount,
        answeredEras: {
          for (final name in p.answeredEraKeys)
            for (final era in Era.values)
              if (era.name == name) era,
        },
        bookmarkCount: p.bookmarkedQuoteIds.length,
      );
}
