import 'package:flutter_test/flutter_test.dart';
import 'package:philosophie_quiz/data/models/achievement.dart';
import 'package:philosophie_quiz/data/models/answer_input_style.dart';
import 'package:philosophie_quiz/data/models/philosopher.dart';
import 'package:philosophie_quiz/data/models/player_profile.dart';
import 'package:philosophie_quiz/data/models/player_stats.dart';
import 'package:philosophie_quiz/data/services/achievement_engine.dart';

PlayerProfile _freshProfile() => PlayerProfile.fresh(
      id: 'test-id',
      displayName: 'Tester',
    );

PlayerStats _statsWith({
  int totalGamesPlayed = 0,
  int totalCorrect = 0,
  int streakDays = 0,
  int bestSuddenDeath = 0,
  int flawlessClassicCount = 0,
  int fastCorrectAnswers = 0,
  int duelsWon = 0,
  int bestDuelStreak = 0,
  int nightSessionsCount = 0,
  Set<Era> answeredEras = const {},
  int bookmarkCount = 0,
}) =>
    PlayerStats(
      totalGamesPlayed: totalGamesPlayed,
      totalCorrect: totalCorrect,
      streakDays: streakDays,
      bestSuddenDeath: bestSuddenDeath,
      flawlessClassicCount: flawlessClassicCount,
      fastCorrectAnswers: fastCorrectAnswers,
      duelsWon: duelsWon,
      bestDuelStreak: bestDuelStreak,
      nightSessionsCount: nightSessionsCount,
      answeredEras: answeredEras,
      bookmarkCount: bookmarkCount,
    );

void main() {
  group('AchievementEngine.evaluate', () {
    test('single-tier achievement unlocks on first crossing of target', () {
      final profile = _freshProfile();
      final stats = _statsWith(totalGamesPlayed: 1);

      final unlocked =
          AchievementEngine.evaluate(profile: profile, stats: stats);

      expect(unlocked.map((u) => u.tierId), contains('first_steps'));
      expect(profile.unlockedAchievements, contains('first_steps'));
    });

    test('multi-tier achievement awards each rung as the player crosses it',
        () {
      final profile = _freshProfile();

      // Bronze threshold (10 correct).
      var unlocked = AchievementEngine.evaluate(
        profile: profile,
        stats: _statsWith(totalCorrect: 10),
      );
      expect(unlocked.map((u) => u.tierId), ['correct_answers.bronze']);

      // Crossing silver should award only silver — bronze stays earned.
      unlocked = AchievementEngine.evaluate(
        profile: profile,
        stats: _statsWith(totalCorrect: 50),
      );
      expect(unlocked.map((u) => u.tierId), ['correct_answers.silver']);
      expect(
        profile.unlockedAchievements,
        containsAll(['correct_answers.bronze', 'correct_answers.silver']),
      );
    });

    test('large jump awards all freshly-crossed tiers at once', () {
      final profile = _freshProfile();

      final unlocked = AchievementEngine.evaluate(
        profile: profile,
        stats: _statsWith(totalCorrect: 100),
      );

      expect(unlocked.map((u) => u.tierId), [
        'correct_answers.bronze',
        'correct_answers.silver',
        'correct_answers.gold',
      ]);
    });

    test('evaluation is idempotent — re-running with same stats unlocks nothing',
        () {
      final profile = _freshProfile();
      final stats = _statsWith(
        totalGamesPlayed: 1,
        totalCorrect: 10,
        streakDays: 3,
      );

      AchievementEngine.evaluate(profile: profile, stats: stats);
      final second =
          AchievementEngine.evaluate(profile: profile, stats: stats);

      expect(second, isEmpty);
    });

    test('hidden achievement appears in unlocks once trigger fires', () {
      final profile = _freshProfile();
      final unlocked = AchievementEngine.evaluate(
        profile: profile,
        stats: _statsWith(nightSessionsCount: 1),
      );
      expect(unlocked.map((u) => u.tierId), contains('midnight_thinker.bronze'));
    });

    test('set-size progress drives all_eras', () {
      final profile = _freshProfile();
      final unlocked = AchievementEngine.evaluate(
        profile: profile,
        stats: _statsWith(answeredEras: Era.values.toSet()),
      );
      expect(unlocked.map((u) => u.tierId), contains('all_eras'));
    });

    test("doesn't unlock when value is one below target", () {
      final profile = _freshProfile();
      final unlocked = AchievementEngine.evaluate(
        profile: profile,
        stats: _statsWith(totalCorrect: 9),
      );
      expect(
        unlocked.map((u) => u.tierId),
        isNot(contains('correct_answers.bronze')),
      );
    });

    test('UnlockedTier.title uses tier override when present', () {
      final ach = achievementById('correct_answers')!;
      final bronze = ach.tiers.first;
      final unlock = UnlockedTier(achievement: ach, tier: bronze);
      expect(unlock.title, 'Schüler des Sokrates');
    });

    test('UnlockedTier.title falls back to base title for single-tier', () {
      final ach = achievementById('first_steps')!;
      final unlock = UnlockedTier(achievement: ach, tier: ach.tiers.first);
      expect(unlock.title, 'Erste Schritte');
    });
  });

  group('AchievementEngine.snapshotFor', () {
    test('reports fraction towards the next tier', () {
      final ach = achievementById('correct_answers')!;
      final stats = _statsWith(totalCorrect: 5);
      final snap = AchievementEngine.snapshotFor(
        achievement: ach,
        stats: stats,
        unlockedIds: const {},
      );
      expect(snap.currentValue, 5);
      expect(snap.nextTier?.target, 10);
      expect(snap.fraction, closeTo(0.5, 1e-9));
      expect(snap.isFullyUnlocked, isFalse);
    });

    test('reports fully unlocked when every tier is earned', () {
      final ach = achievementById('correct_answers')!;
      final snap = AchievementEngine.snapshotFor(
        achievement: ach,
        stats: _statsWith(totalCorrect: 999),
        unlockedIds: const {
          'correct_answers.bronze',
          'correct_answers.silver',
          'correct_answers.gold',
        },
      );
      expect(snap.isFullyUnlocked, isTrue);
      expect(snap.fraction, 1.0);
      expect(snap.bestUnlockedTier?.level, TierLevel.gold);
    });
  });

  group('Achievement model helpers', () {
    test('tierIdOf collapses single-tier achievements to bare id', () {
      final ach = achievementById('first_steps')!;
      expect(ach.tierIdOf(ach.tiers.first), 'first_steps');
    });

    test('tierIdOf composes <id>.<level> for multi-tier achievements', () {
      final ach = achievementById('streaks')!;
      expect(ach.tierIdOf(ach.tiers[0]), 'streaks.bronze');
      expect(ach.tierIdOf(ach.tiers[1]), 'streaks.silver');
      expect(ach.tierIdOf(ach.tiers[2]), 'streaks.gold');
    });

    test('bestUnlocked returns the highest-rank earned tier', () {
      final ach = achievementById('streaks')!;
      final best = ach.bestUnlocked({'streaks.bronze', 'streaks.silver'});
      expect(best?.level, TierLevel.silver);
    });

    test('nextTier returns the lowest still-locked tier, null if all earned',
        () {
      final ach = achievementById('streaks')!;
      expect(ach.nextTier({'streaks.bronze'})?.level, TierLevel.silver);
      expect(
        ach.nextTier({'streaks.bronze', 'streaks.silver', 'streaks.gold'}),
        isNull,
      );
    });
  });

  // Sanity: keep the persisted-profile constructor in sync with the engine
  // by round-tripping every counter through PlayerStats.
  test('PlayerStats.fromProfile mirrors every persisted counter', () {
    final p = PlayerProfile(
      id: 'x',
      displayName: 'x',
      avatarSeal: 'Σ',
      xp: 0,
      streakDays: 4,
      lastPlayedDate: null,
      totalGamesPlayed: 12,
      totalCorrect: 35,
      bestSuddenDeath: 17,
      flawlessClassicCount: 2,
      fastCorrectAnswers: 21,
      duelsWon: 3,
      currentDuelStreak: 1,
      bestDuelStreak: 4,
      nightSessionsCount: 1,
      answeredEraKeys: {'antike', 'aufklaerung'},
      unlockedAchievements: const {},
      bookmarkedQuoteIds: const {'q_quote_001', 'q_quote_002'},
      preferredCategories: const {},
      preferredDifficulty: const (1, 5),
      locale: 'de',
      themeMode: 'system',
      soundsEnabled: false,
      hapticsEnabled: true,
      jokerAvailability: JokerAvailability.always,
      preferredInputStyle: AnswerInputStyle.multipleChoice,
    );

    final stats = PlayerStats.fromProfile(p);

    expect(stats.totalGamesPlayed, 12);
    expect(stats.totalCorrect, 35);
    expect(stats.streakDays, 4);
    expect(stats.bestSuddenDeath, 17);
    expect(stats.flawlessClassicCount, 2);
    expect(stats.fastCorrectAnswers, 21);
    expect(stats.duelsWon, 3);
    expect(stats.bestDuelStreak, 4);
    expect(stats.nightSessionsCount, 1);
    expect(stats.bookmarkCount, 2);
    expect(stats.answeredEras, {Era.antike, Era.aufklaerung});
  });
}
