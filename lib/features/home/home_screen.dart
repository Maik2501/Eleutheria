import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/game_session.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/wax_seal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final profile = ref.watch(profileNotifierProvider).value;

    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: WaxSeal(
                          symbol: profile?.avatarSeal ?? 'Σ',
                          size: 52,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guten Tag,',
                              style: AppTypography.eyebrow(palette.gold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile?.displayName ?? '…',
                              style: AppTypography.serif(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: palette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StreakBadge(days: profile?.streakDays ?? 0),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 8),
                  child: ChapterHeading(
                    eyebrow: 'Sophia',
                    title: 'Was möchtest du heute\nlesen, fragen, denken?',
                    subtitle: 'Wähle einen Modus.',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: _DailyChallengeCard(
                    onTap: () => context.push('/play/daily'),
                  ).animate().fadeIn(duration: 380.ms).moveY(
                        begin: 8,
                        end: 0,
                        duration: 380.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    _ModeTile(
                      mode: GameMode.classic,
                      icon: '◇',
                      onTap: () => context.push('/play/classic'),
                    ),
                    _CustomTile(
                      title: 'Buchstabenrätsel',
                      subtitle: 'Antworten selbst eintippen',
                      icon: '▦',
                      onTap: () => context.push('/play/letterbox'),
                    ),
                    _CustomTile(
                      title: 'Kreuzworträtsel',
                      subtitle: 'Echtes Rätsel mit kreuzenden Wörtern',
                      icon: '☷',
                      onTap: () => context.push('/crossword'),
                    ),
                    _ModeTile(
                      mode: GameMode.suddenDeath,
                      icon: '⚜',
                      onTap: () => context.push('/play/sudden-death'),
                    ),
                    _ModeTile(
                      mode: GameMode.vsOnline,
                      icon: '⚔',
                      onTap: () => context.push('/duel'),
                      accent: true,
                    ),
                    _ModeTile(
                      mode: GameMode.practice,
                      icon: '✦',
                      onTap: () => context.push('/practice'),
                    ),
                    _ModeTile(
                      mode: GameMode.category,
                      icon: '◈',
                      onTap: () => context.push('/categories'),
                    ),
                    _LeaderboardTile(
                      onTap: () => context.push('/leaderboard'),
                    ),
                  ]
                      .animate(interval: 60.ms)
                      .fadeIn(duration: 320.ms)
                      .moveY(begin: 12, end: 0, curve: Curves.easeOutCubic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('☼', style: TextStyle(fontSize: 16, color: palette.gold)),
          const SizedBox(width: 6),
          Text(
            '$days',
            style: AppTypography.serif(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.burgundy, AppColors.burgundyDeep],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: palette.burgundy.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.gold.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Text(
                '☀',
                style: TextStyle(fontSize: 26, color: palette.gold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TÄGLICHE FRAGE',
                    style: AppTypography.eyebrow(palette.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fünf Fragen für alle.',
                    style: AppTypography.serif(
                      fontWeight: FontWeight.w600,
                      fontSize: 19,
                      color: AppColors.page,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vergleiche deinen Score mit der Welt.',
                    style: AppTypography.sans(
                      color: AppColors.page.withValues(alpha: 0.78),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.page.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  final GameMode mode;
  final String icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: icon,
      title: mode.title,
      subtitle: mode.subtitle,
      onTap: onTap,
      accent: accent,
    );
  }
}

class _CustomTile extends StatelessWidget {
  const _CustomTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: '☗',
      title: 'Rangliste',
      subtitle: 'Tageswerte und Bestenliste',
      onTap: onTap,
      iconColor: context.palette.gold,
    );
  }
}

/// Shared tile chrome — keeps icon, title and subtitle on a consistent
/// vertical rhythm so the grid reads as a single layout, not eight one-offs.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
    this.iconColor,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolvedIconColor = iconColor ?? (accent ? palette.gold : palette.burgundy);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent ? palette.gold.withValues(alpha: 0.55) : palette.divider,
              width: accent ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: resolvedIconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: AppTypography.serif(
                      fontSize: 22,
                      color: resolvedIconColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: AppTypography.serif(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: palette.ink,
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTypography.sans(
                  fontSize: 12.5,
                  height: 1.35,
                  color: palette.inkMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
