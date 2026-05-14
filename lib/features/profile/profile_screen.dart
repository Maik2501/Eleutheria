import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/achievement.dart';
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
            Center(child: WaxSeal(symbol: p.avatarSeal, size: 92)),
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
            _XpBar(progress: progress, current: p.xpIntoCurrentLevel, target: p.xpForNextLevel),
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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
              children: [
                for (final a in kAchievements)
                  _AchievementBadge(
                    achievement: a,
                    unlocked: p.unlockedAchievements.contains(a.id),
                  ),
              ],
            ),
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
    if (newName != null && newName.isNotEmpty) {
      await ref.read(profileNotifierProvider.notifier).renameTo(newName);
    }
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
            Text('Fortschritt zur nächsten Stufe',
                style: AppTypography.eyebrow(palette.inkMuted),),
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
          Text(label.toUpperCase(),
              style: AppTypography.eyebrow(palette.inkMuted),),
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

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.achievement,
    required this.unlocked,
  });

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Opacity(
      opacity: unlocked ? 1 : 0.32,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.page,
          border: Border.all(
            color: unlocked
                ? palette.gold.withValues(alpha: 0.6)
                : palette.divider,
            width: unlocked ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            WaxSeal(
              symbol: achievement.symbol,
              size: 36,
              color: unlocked ? palette.gold : palette.inkMuted,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.serif(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
