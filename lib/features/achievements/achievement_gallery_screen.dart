import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/achievement.dart';
import '../../data/models/player_profile.dart';
import '../../data/models/player_stats.dart';
import '../../data/services/achievement_engine.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/wax_seal.dart';

/// Full-page Errungenschaften gallery, reachable from the home-header rank
/// chip and the profile screen. Per-category tabs, per-achievement progress
/// bars, tier indicators, and a bottom-sheet detail view.
class AchievementGalleryScreen extends ConsumerStatefulWidget {
  const AchievementGalleryScreen({super.key});

  @override
  ConsumerState<AchievementGalleryScreen> createState() =>
      _AchievementGalleryScreenState();
}

class _AchievementGalleryScreenState
    extends ConsumerState<AchievementGalleryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _categories.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const _categories = AchievementCategory.values;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = ref.watch(profileNotifierProvider).value;
    if (p == null) return const SizedBox.shrink();

    final stats = PlayerStats.fromProfile(p);

    // Hide unrevealed hidden achievements; reveal them once a tier lands.
    final visible = kAchievements
        .where((a) => !a.hidden || a.isAnyUnlocked(p.unlockedAchievements))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Errungenschaften'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: palette.gold,
          labelColor: palette.ink,
          unselectedLabelColor: palette.inkMuted,
          tabs: [
            const Tab(text: 'Alle'),
            for (final c in _categories) Tab(text: c.label),
          ],
        ),
      ),
      body: ParchmentBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _GalleryHeader(profile: p, total: kAchievements.length),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: DecorativeRule(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _AchievementList(
                      achievements: visible,
                      stats: stats,
                      unlockedIds: p.unlockedAchievements,
                    ),
                    for (final c in _categories)
                      _AchievementList(
                        achievements: visible
                            .where((a) => a.category == c)
                            .toList(growable: false),
                        stats: stats,
                        unlockedIds: p.unlockedAchievements,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({required this.profile, required this.total});
  final PlayerProfile profile;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // Count unique achievements with at least one tier unlocked, plus total
    // tiers earned vs. total available (gives a denser, more rewarding number).
    final unlockedCount = kAchievements
        .where((a) => a.isAnyUnlocked(profile.unlockedAchievements))
        .length;
    final totalTiers =
        kAchievements.fold<int>(0, (sum, a) => sum + a.tiers.length);
    final earnedTiers = kAchievements.fold<int>(
      0,
      (sum, a) =>
          sum +
          a.tiers
              .where(
                (t) => profile.unlockedAchievements.contains(a.tierIdOf(t)),
              )
              .length,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.rankTitle.toUpperCase()} · STUFE ${profile.level}',
                  style: AppTypography.eyebrow(palette.gold),
                ),
                const SizedBox(height: 6),
                Text(
                  '$unlockedCount von $total entsiegelt',
                  style: AppTypography.serif(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$earnedTiers von $totalTiers Stufen erreicht',
                  style: TextStyle(
                    color: palette.inkMuted,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          WaxSeal(
            symbol: profile.avatarSeal,
            size: 60,
            color: palette.burgundy,
          ),
        ],
      ),
    );
  }
}

class _AchievementList extends StatelessWidget {
  const _AchievementList({
    required this.achievements,
    required this.stats,
    required this.unlockedIds,
  });

  final List<Achievement> achievements;
  final PlayerStats stats;
  final Set<String> unlockedIds;

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'Hier ist noch nichts.',
          style: TextStyle(color: context.palette.inkMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      itemCount: achievements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final ach = achievements[i];
        final snap = AchievementEngine.snapshotFor(
          achievement: ach,
          stats: stats,
          unlockedIds: unlockedIds,
        );
        return _AchievementCard(
          achievement: ach,
          snap: snap,
          unlockedIds: unlockedIds,
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.snap,
    required this.unlockedIds,
  });

  final Achievement achievement;
  final AchievementProgressSnapshot snap;
  final Set<String> unlockedIds;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final best = snap.bestUnlockedTier;
    final displayTier = best ?? achievement.tiers.first;
    final unlocked = best != null;
    final tint = unlocked ? displayTier.level.tint : palette.inkMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _AchievementDetailSheet.show(
          context,
          achievement: achievement,
          snap: snap,
          unlockedIds: unlockedIds,
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.page,
            border: Border.all(
              color: unlocked ? tint.withValues(alpha: 0.55) : palette.divider,
              width: unlocked ? 1.3 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: unlocked ? 1 : 0.4,
                child: WaxSeal(
                  symbol: displayTier.symbol,
                  size: 48,
                  color: tint,
                  assetPath: achievement.assetPathOf(displayTier),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            unlocked
                                ? (displayTier.titleOverride ??
                                    achievement.title)
                                : achievement.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.serif(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (achievement.isMultiTier)
                          _TierDots(
                            achievement: achievement,
                            unlockedIds: unlockedIds,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.inkMuted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ProgressLine(snap: snap, tint: tint, unlocked: unlocked),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierDots extends StatelessWidget {
  const _TierDots({required this.achievement, required this.unlockedIds});
  final Achievement achievement;
  final Set<String> unlockedIds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final t in achievement.tiers) ...[
          const SizedBox(width: 4),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlockedIds.contains(achievement.tierIdOf(t))
                  ? t.level.tint
                  : context.palette.divider,
              border: Border.all(
                color: t.level.tint.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.snap,
    required this.tint,
    required this.unlocked,
  });

  final AchievementProgressSnapshot snap;
  final Color tint;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (snap.isFullyUnlocked) {
      return Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: tint),
          const SizedBox(width: 6),
          Text(
            'Alle Stufen erreicht',
            style: TextStyle(
              color: tint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final next = snap.nextTier!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: snap.fraction,
            minHeight: 5,
            backgroundColor: palette.divider,
            valueColor: AlwaysStoppedAnimation(tint),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unlocked
              ? '${snap.currentValue} / ${next.target} bis ${next.level.label}'
              : '${snap.currentValue} / ${next.target}',
          style: TextStyle(color: palette.inkMuted, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  const _AchievementDetailSheet({
    required this.achievement,
    required this.snap,
    required this.unlockedIds,
  });

  final Achievement achievement;
  final AchievementProgressSnapshot snap;
  final Set<String> unlockedIds;

  static Future<void> show(
    BuildContext context, {
    required Achievement achievement,
    required AchievementProgressSnapshot snap,
    required Set<String> unlockedIds,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.page,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AchievementDetailSheet(
        achievement: achievement,
        snap: snap,
        unlockedIds: unlockedIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final best = snap.bestUnlockedTier;
    final tier = best ?? achievement.tiers.first;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                WaxSeal(
                  symbol: tier.symbol,
                  size: 64,
                  color: best != null ? tier.level.tint : palette.inkMuted,
                  assetPath: achievement.assetPathOf(tier),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: AppTypography.serif(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.category.label,
                        style: AppTypography.eyebrow(palette.gold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              achievement.description,
              style: TextStyle(color: palette.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 20),
            for (final t in achievement.tiers) ...[
              _TierRow(
                tier: t,
                unlocked: unlockedIds.contains(achievement.tierIdOf(t)),
                isCurrent: snap.nextTier == t,
                currentValue: snap.currentValue,
              ),
              if (t != achievement.tiers.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.unlocked,
    required this.isCurrent,
    required this.currentValue,
  });

  final AchievementTier tier;
  final bool unlocked;
  final bool isCurrent;
  final int currentValue;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = unlocked ? tier.level.tint : palette.inkMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? tint.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? palette.gold.withValues(alpha: 0.6)
              : palette.divider,
          width: isCurrent ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: unlocked ? 1 : 0.18),
              border: Border.all(color: tint, width: 1.4),
            ),
            child: unlocked
                ? const Icon(Icons.check_rounded,
                    size: 18, color: Colors.white,)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.titleOverride != null
                      ? '${tier.level.label} · ${tier.titleOverride}'
                      : tier.level.label,
                  style: AppTypography.serif(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                Text(
                  unlocked
                      ? 'Geschafft'
                      : '$currentValue / ${tier.target}',
                  style: TextStyle(color: palette.inkMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
