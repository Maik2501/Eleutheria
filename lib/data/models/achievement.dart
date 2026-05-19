import 'package:flutter/material.dart';

import 'player_stats.dart';

/// Declarative achievement definition with optional tiered progression.
///
/// An Achievement bundles together:
///   - identity ([id], [title], [description]) shown in UI
///   - a [progressOf] function that maps a [PlayerStats] snapshot to an
///     integer "current value" (compared against tier targets)
///   - one or more [tiers] — each with its own target threshold, symbol, and
///     tier level (bronze/silver/gold)
///
/// A single-tier achievement uses just [TierLevel.bronze]; the engine still
/// treats it uniformly. Tier-ids are composed as `<id>.<tier>` (e.g.
/// `streaks.silver`); single-tier achievements keep their bare id so that
/// legacy persisted unlocks remain valid where possible — see
/// `ProfileRepository._migrateLegacyAchievementIds`.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tiers,
    required this.progressOf,
    this.hidden = false,
  });

  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final List<AchievementTier> tiers;
  final int Function(PlayerStats stats) progressOf;

  /// Hidden achievements appear as silhouettes in the gallery until at least
  /// one tier is unlocked.
  final bool hidden;

  bool get isMultiTier => tiers.length > 1;

  /// Compose the persisted tier-id for a given tier of this achievement.
  /// Single-tier achievements keep the bare id (for backwards-compat).
  String tierIdOf(AchievementTier tier) =>
      isMultiTier ? '$id.${tier.level.name}' : id;

  /// Asset path for the icon of a given tier. Single-tier achievements use
  /// `<id>.webp`, multi-tier ones `<id>_<level>.webp`. The widget that renders
  /// this falls back to the procedural wax seal if the file is missing, so
  /// returning a path here is safe even when the asset hasn't shipped yet.
  String assetPathOf(AchievementTier tier) {
    final base = isMultiTier ? '${id}_${tier.level.name}' : id;
    return 'assets/icons/achievements/$base.webp';
  }

  /// Best tier the player has actually unlocked, or null.
  AchievementTier? bestUnlocked(Set<String> unlockedIds) {
    AchievementTier? best;
    for (final tier in tiers) {
      if (unlockedIds.contains(tierIdOf(tier))) best = tier;
    }
    return best;
  }

  /// Next tier still to be earned, or null if everything is unlocked.
  AchievementTier? nextTier(Set<String> unlockedIds) {
    for (final tier in tiers) {
      if (!unlockedIds.contains(tierIdOf(tier))) return tier;
    }
    return null;
  }

  /// Whether at least one tier is unlocked.
  bool isAnyUnlocked(Set<String> unlockedIds) =>
      tiers.any((t) => unlockedIds.contains(tierIdOf(t)));

  /// Whether every tier is unlocked.
  bool isFullyUnlocked(Set<String> unlockedIds) =>
      tiers.every((t) => unlockedIds.contains(tierIdOf(t)));
}

/// A single rung on a tiered achievement.
class AchievementTier {
  const AchievementTier({
    required this.level,
    required this.symbol,
    required this.target,
    this.titleOverride,
  });

  final TierLevel level;

  /// Glyph rendered inside the wax seal (e.g. 'Σ', 'Φ').
  final String symbol;

  /// Threshold the player has to reach to unlock this tier.
  final int target;

  /// Tier-specific title shown instead of the achievement's base title
  /// (used when a tiered achievement gives each rung its own "rank name",
  /// e.g. Sokrates → Plato → Aristoteles).
  final String? titleOverride;
}

enum TierLevel {
  bronze,
  silver,
  gold;

  /// Warm-academia tint per tier, blends with the wax-seal radial gradient.
  Color get tint => switch (this) {
        TierLevel.bronze => const Color(0xFFA97142),
        TierLevel.silver => const Color(0xFFC2BBA8),
        TierLevel.gold => const Color(0xFFD4A24C),
      };

  String get label => switch (this) {
        TierLevel.bronze => 'Bronze',
        TierLevel.silver => 'Silber',
        TierLevel.gold => 'Gold',
      };
}

enum AchievementCategory {
  milestone('Meilensteine'),
  mastery('Meisterung'),
  streak('Beharrlichkeit'),
  social('Im Disput');

  const AchievementCategory(this.label);
  final String label;
}

/// Per-achievement progress helpers used by the registry (kept as top-level
/// tear-offs so `const Achievement(...)` stays const-constructible).
int _firstStepsProgress(PlayerStats s) => s.totalGamesPlayed;
int _totalCorrectProgress(PlayerStats s) => s.totalCorrect;
int _streakProgress(PlayerStats s) => s.streakDays;
int _suddenDeathProgress(PlayerStats s) => s.bestSuddenDeath;
int _flawlessClassicProgress(PlayerStats s) => s.flawlessClassicCount;
int _speedDemonProgress(PlayerStats s) => s.fastCorrectAnswers;
int _erasCoveredProgress(PlayerStats s) => s.answeredEras.length;
int _duelsWonProgress(PlayerStats s) => s.duelsWon;
int _duelStreakProgress(PlayerStats s) => s.bestDuelStreak;
int _bookmarksProgress(PlayerStats s) => s.bookmarkCount;
int _midnightProgress(PlayerStats s) => s.nightSessionsCount;

/// Canonical achievement registry. Order = display order in the gallery.
const List<Achievement> kAchievements = [
  Achievement(
    id: 'first_steps',
    title: 'Erste Schritte',
    description: 'Spiele dein erstes Quiz.',
    category: AchievementCategory.milestone,
    progressOf: _firstStepsProgress,
    tiers: [
      AchievementTier(level: TierLevel.bronze, symbol: 'I', target: 1),
    ],
  ),
  Achievement(
    id: 'correct_answers',
    title: 'Sammler der Wahrheiten',
    description: 'Sammle richtige Antworten über alle Spielmodi.',
    category: AchievementCategory.milestone,
    progressOf: _totalCorrectProgress,
    tiers: [
      AchievementTier(
        level: TierLevel.bronze,
        symbol: 'Σ',
        target: 10,
        titleOverride: 'Schüler des Sokrates',
      ),
      AchievementTier(
        level: TierLevel.silver,
        symbol: 'Π',
        target: 50,
        titleOverride: 'Platons Geselle',
      ),
      AchievementTier(
        level: TierLevel.gold,
        symbol: 'A',
        target: 100,
        titleOverride: "Aristoteles' Logiker",
      ),
    ],
  ),
  Achievement(
    id: 'streaks',
    title: 'Beharrlichkeit',
    description: 'Spiele Tag für Tag in Folge.',
    category: AchievementCategory.streak,
    progressOf: _streakProgress,
    tiers: [
      AchievementTier(
        level: TierLevel.bronze,
        symbol: '☼',
        target: 3,
        titleOverride: 'Kontinuität',
      ),
      AchievementTier(
        level: TierLevel.silver,
        symbol: '✦',
        target: 7,
        titleOverride: 'Wöchentliche Disziplin',
      ),
      AchievementTier(
        level: TierLevel.gold,
        symbol: '⚜',
        target: 30,
        titleOverride: 'Stoische Beharrlichkeit',
      ),
    ],
  ),
  Achievement(
    id: 'sudden_death',
    title: 'Im Angesicht des Fehlers',
    description: 'Halte eine Serie im Sudden-Death-Modus.',
    category: AchievementCategory.mastery,
    progressOf: _suddenDeathProgress,
    tiers: [
      AchievementTier(
        level: TierLevel.bronze,
        symbol: 'Φ',
        target: 10,
        titleOverride: 'Phönix',
      ),
      AchievementTier(
        level: TierLevel.silver,
        symbol: 'Ψ',
        target: 25,
        titleOverride: 'Unbeirrbar',
      ),
      AchievementTier(
        level: TierLevel.gold,
        symbol: 'Ω',
        target: 50,
        titleOverride: 'Stoische Härte',
      ),
    ],
  ),
  Achievement(
    id: 'flawless_classic',
    title: 'Tabula Perfecta',
    description: 'Klassisches Quiz ohne einen Fehler.',
    category: AchievementCategory.mastery,
    progressOf: _flawlessClassicProgress,
    tiers: [
      AchievementTier(level: TierLevel.bronze, symbol: '✪', target: 1),
      AchievementTier(level: TierLevel.silver, symbol: '✩', target: 5),
      AchievementTier(level: TierLevel.gold, symbol: '✶', target: 20),
    ],
  ),
  Achievement(
    id: 'speed_demon',
    title: 'Schnelldenker',
    description: 'Beantworte Fragen in unter drei Sekunden korrekt.',
    category: AchievementCategory.mastery,
    progressOf: _speedDemonProgress,
    tiers: [
      AchievementTier(level: TierLevel.bronze, symbol: '⚡', target: 10),
      AchievementTier(level: TierLevel.silver, symbol: '⚡', target: 50),
      AchievementTier(level: TierLevel.gold, symbol: '⚡', target: 200),
    ],
  ),
  Achievement(
    id: 'all_eras',
    title: 'Reise durch die Zeit',
    description: 'Beantworte richtige Fragen aus allen Epochen.',
    category: AchievementCategory.mastery,
    progressOf: _erasCoveredProgress,
    tiers: [
      AchievementTier(level: TierLevel.bronze, symbol: '⌛', target: 7),
    ],
  ),
  Achievement(
    id: 'bookmarks',
    title: 'Sammler der Worte',
    description: 'Markiere Lieblingszitate für die persönliche Bibliothek.',
    category: AchievementCategory.mastery,
    progressOf: _bookmarksProgress,
    tiers: [
      AchievementTier(level: TierLevel.bronze, symbol: '❦', target: 5),
      AchievementTier(level: TierLevel.silver, symbol: '❦', target: 25),
      AchievementTier(level: TierLevel.gold, symbol: '❦', target: 100),
    ],
  ),
  Achievement(
    id: 'first_duel_won',
    title: 'Erster Sieg',
    description: 'Gewinne dein erstes Duell.',
    category: AchievementCategory.social,
    progressOf: _duelsWonProgress,
    tiers: [
      AchievementTier(level: TierLevel.bronze, symbol: '⚔', target: 1),
    ],
  ),
  Achievement(
    id: 'duel_streak',
    title: 'Eristik',
    description: 'Gewinne Duelle in Folge.',
    category: AchievementCategory.social,
    progressOf: _duelStreakProgress,
    tiers: [
      AchievementTier(level: TierLevel.bronze, symbol: '✠', target: 3),
      AchievementTier(level: TierLevel.silver, symbol: '✠', target: 5),
      AchievementTier(level: TierLevel.gold, symbol: '✠', target: 10),
    ],
  ),
  Achievement(
    id: 'midnight_thinker',
    title: 'Nachtwanderer',
    description: 'Philosophiere zwischen Mitternacht und Morgengrauen.',
    category: AchievementCategory.mastery,
    progressOf: _midnightProgress,
    hidden: true,
    tiers: [
      AchievementTier(level: TierLevel.bronze, symbol: '☾', target: 1),
      AchievementTier(level: TierLevel.silver, symbol: '☾', target: 5),
      AchievementTier(level: TierLevel.gold, symbol: '☾', target: 20),
    ],
  ),
];

/// Lookup helper.
Achievement? achievementById(String id) {
  for (final a in kAchievements) {
    if (a.id == id) return a;
  }
  return null;
}
