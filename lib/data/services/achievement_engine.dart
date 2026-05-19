import '../models/achievement.dart';
import '../models/player_profile.dart';
import '../models/player_stats.dart';

/// Result of an evaluation pass — the set of tier-ids the player just earned.
///
/// The engine is intentionally idempotent: passing the same stats twice yields
/// no further unlocks, because the engine compares the freshly computed
/// progress against what's already persisted in
/// [PlayerProfile.unlockedAchievements].
class UnlockedTier {
  const UnlockedTier({
    required this.achievement,
    required this.tier,
  });

  final Achievement achievement;
  final AchievementTier tier;

  /// Persisted id (e.g. `streaks.silver` or `first_steps`).
  String get tierId => achievement.tierIdOf(tier);

  /// Display title — tier override wins over base achievement title for
  /// multi-tier rungs that carry their own rank name.
  String get title => tier.titleOverride ?? achievement.title;
}

/// Walks [kAchievements], compares each tier's [AchievementTier.target] to the
/// current value from [PlayerStats], and returns whatever just crossed the
/// threshold for the first time. Mutates [PlayerProfile.unlockedAchievements]
/// in-place with the new tier ids.
class AchievementEngine {
  const AchievementEngine._();

  /// Evaluate every achievement, return any newly unlocked tiers, ordered
  /// roughly by achievement registry order then bronze→silver→gold so the
  /// celebration UI can stagger them naturally.
  static List<UnlockedTier> evaluate({
    required PlayerProfile profile,
    required PlayerStats stats,
  }) {
    final already = profile.unlockedAchievements;
    final freshlyUnlocked = <UnlockedTier>[];
    final additions = <String>{};

    for (final achievement in kAchievements) {
      final value = achievement.progressOf(stats);
      for (final tier in achievement.tiers) {
        if (value < tier.target) continue;
        final id = achievement.tierIdOf(tier);
        if (already.contains(id) || additions.contains(id)) continue;
        additions.add(id);
        freshlyUnlocked.add(
          UnlockedTier(achievement: achievement, tier: tier),
        );
      }
    }

    if (additions.isNotEmpty) {
      profile.unlockedAchievements = {...already, ...additions};
    }
    return freshlyUnlocked;
  }

  /// Progress snapshot for a single achievement — current value vs. the next
  /// tier's target. Used by the gallery UI to render progress bars on the
  /// rungs the player is currently chasing.
  static AchievementProgressSnapshot snapshotFor({
    required Achievement achievement,
    required PlayerStats stats,
    required Set<String> unlockedIds,
  }) {
    final value = achievement.progressOf(stats);
    final next = achievement.nextTier(unlockedIds);
    final best = achievement.bestUnlocked(unlockedIds);
    return AchievementProgressSnapshot(
      currentValue: value,
      nextTier: next,
      bestUnlockedTier: best,
    );
  }
}

class AchievementProgressSnapshot {
  const AchievementProgressSnapshot({
    required this.currentValue,
    required this.nextTier,
    required this.bestUnlockedTier,
  });

  final int currentValue;
  final AchievementTier? nextTier;
  final AchievementTier? bestUnlockedTier;

  bool get isFullyUnlocked => nextTier == null;

  /// 0..1 progress towards [nextTier]. 1.0 when fully unlocked.
  double get fraction {
    final target = nextTier?.target;
    if (target == null || target <= 0) return 1;
    return (currentValue / target).clamp(0, 1).toDouble();
  }
}
