import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/achievement.dart';
import '../../data/models/player_profile.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../shared/widgets/brand_seal.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/wax_seal.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final p = ref.watch(profileNotifierProvider).value;
    if (p == null) return const SizedBox.shrink();

    final progress =
        p.xpForNextLevel == 0 ? 0.0 : p.xpIntoCurrentLevel / p.xpForNextLevel;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Profil'),
      ),
      body: ParchmentBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            const SizedBox(height: 8),
            const Center(child: BrandSeal(size: 92)),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () => _editName(context, ref),
                child: Text(
                  p.displayName,
                  textAlign: TextAlign.center,
                  style: AppTypography.serif(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${p.rankTitle} · Stufe ${p.level}',
                style: TextStyle(color: palette.inkMuted, fontSize: 13.5),
              ),
            ),
            const SizedBox(height: 18),
            _XpBar(
              progress: progress,
              current: p.xpIntoCurrentLevel,
              target: p.xpForNextLevel,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Spiele',
                    value: '${p.totalGamesPlayed}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: 'Richtig',
                    value: '${p.totalCorrect}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: 'Best ⚜',
                    value: '${p.bestSuddenDeath}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const ChapterHeading(
              eyebrow: 'Sammlung',
              title: 'Errungenschaften',
            ),
            const SizedBox(height: 16),
            _AchievementsPreview(profile: p),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final p = ref.read(profileNotifierProvider).value;
    if (p == null) return;
    final ctrl = TextEditingController(text: p.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.palette.page,
        title: const Text('Name ändern'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    final trimmed = newName?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == p.displayName) {
      return;
    }

    final remoteRepo = ref.read(supabaseProfileRepositoryProvider);
    if (remoteRepo == null) {
      await ref.read(profileNotifierProvider.notifier).renameTo(trimmed);
      return;
    }

    final result = await remoteRepo.reserve(trimmed);
    if (!context.mounted) return;

    switch (result) {
      case ReservationOk(displayName: final reservedName):
        await ref.read(profileNotifierProvider.notifier).renameTo(reservedName);
        ref.invalidate(remoteProfileProvider);
      case ReservationTaken(suggestions: final suggestions):
        final suffix =
            suggestions.isEmpty ? '' : ' Vorschlag: ${suggestions.first}';
        _showNameError(context, 'Der Name ist schon vergeben.$suffix');
      case ReservationInvalid(reason: final reason):
        _showNameError(context, reason);
      case ReservationOffline():
        _showNameError(context, 'Keine Verbindung. Name wurde nicht geändert.');
      case ReservationError(message: final message):
        _showNameError(context, 'Fehler: $message');
    }
  }

  void _showNameError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({
    required this.progress,
    required this.current,
    required this.target,
  });

  final double progress;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fortschritt zur nächsten Stufe',
              style: AppTypography.eyebrow(palette.inkMuted),
            ),
            Text(
              '$current / $target',
              style: AppTypography.serif(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: palette.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: palette.parchment,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.divider, width: 0.5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0, 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.gold, AppColors.goldDeep],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.eyebrow(palette.inkMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.serif(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: palette.ink,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact summary card on the profile screen — shows the three most recent
/// unlocks (or the next three locked teasers) and an "Alle ansehen"-CTA that
/// pushes the dedicated gallery.
class _AchievementsPreview extends StatelessWidget {
  const _AchievementsPreview({required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final unlockedAchievements = kAchievements
        .where((a) => a.isAnyUnlocked(profile.unlockedAchievements))
        .toList(growable: false);
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

    // Preview pool: prefer unlocked achievements (best-tier glyph), pad with
    // not-yet-unlocked visible ones so the row is always full.
    final visible = kAchievements
        .where((a) => !a.hidden || a.isAnyUnlocked(profile.unlockedAchievements))
        .toList(growable: false);
    final preview = [
      ...unlockedAchievements,
      ...visible.where((a) => !unlockedAchievements.contains(a)),
    ].take(4).toList(growable: false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/achievements'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.page,
            border: Border.all(color: palette.gold.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${unlockedAchievements.length} von ${kAchievements.length} entsiegelt',
                      style: AppTypography.serif(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  Text(
                    '$earnedTiers / $totalTiers Stufen',
                    style:
                        TextStyle(color: palette.inkMuted, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final a in preview)
                    _PreviewSeal(
                      achievement: a,
                      unlockedIds: profile.unlockedAchievements,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Alle ansehen',
                    style: TextStyle(
                      color: palette.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: palette.gold,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSeal extends StatelessWidget {
  const _PreviewSeal({required this.achievement, required this.unlockedIds});
  final Achievement achievement;
  final Set<String> unlockedIds;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final best = achievement.bestUnlocked(unlockedIds);
    final unlocked = best != null;
    final tier = best ?? achievement.tiers.first;
    final tint = unlocked ? tier.level.tint : palette.inkMuted;
    return Opacity(
      opacity: unlocked ? 1 : 0.32,
      child: WaxSeal(
        symbol: tier.symbol,
        size: 44,
        color: tint,
        assetPath: achievement.assetPathOf(tier),
      ),
    );
  }
}
