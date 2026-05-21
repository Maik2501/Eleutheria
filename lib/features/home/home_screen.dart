// ignore_for_file: unused_element, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/achievement.dart';
import '../../data/models/answer_input_style.dart';
import '../../data/models/difficulty_band.dart';
import '../../data/models/game_session.dart';
import '../../data/models/player_profile.dart';
import '../../shared/widgets/brand_seal.dart';
import '../../shared/widgets/parchment_background.dart';
import '../quiz/game_session_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AnswerInputStyle _inputStyle = AnswerInputStyle.multipleChoice;
  DifficultyBand _band = DifficultyBand.salon;
  bool _loadedFromProfile = false;

  Duration get _questionLimit => _inputStyle == AnswerInputStyle.letterbox
      ? const Duration(seconds: 45)
      : const Duration(seconds: 20);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileNotifierProvider).value;
    if (!_loadedFromProfile && profile != null) {
      _inputStyle = profile.preferredInputStyle;
      _band = DifficultyBand.fromRange(
        profile.preferredDifficulty.$1,
        profile.preferredDifficulty.$2,
      );
      _loadedFromProfile = true;
    }

    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HomeHeader(
                  displayName: profile?.displayName ?? '…',
                  streakDays: profile?.streakDays ?? 0,
                  rankTitle: profile?.rankTitle ?? 'Lehrling',
                  level: profile?.level ?? 1,
                  unlockedCount: _unlockedAchievementCount(profile),
                  totalCount: kAchievements.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: _HomeIntroPanel(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
                  child: _AnswerStyleSwitch(
                    value: _inputStyle,
                    onChanged: _setInputStyle,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: _DifficultyBandSwitch(
                    value: _band,
                    onChanged: _setBand,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _ModeCard(
                        iconAsset: 'assets/icons/modes/quiz_rush.webp',
                        backgroundAsset: 'assets/images/modes/quiz_rush.webp',
                        eyebrow: 'Tempo',
                        title: 'Quiz-Rush',
                        description:
                            'So viele richtige Antworten wie möglich. Endless endet nach drei Fehlern.',
                        accent: AppColors.terracotta,
                        children: [
                          _OptionAction(
                            icon: Icons.timer_rounded,
                            label: '1 Minute',
                            meta: 'Best of',
                            onTap: () =>
                                _startQuiz(GameConfig.quizRushOneMinute),
                          ),
                          _OptionAction(
                            icon: Icons.timer_rounded,
                            label: '3 Minuten',
                            meta: 'Best of',
                            onTap: () =>
                                _startQuiz(GameConfig.quizRushThreeMinutes),
                          ),
                          _OptionAction(
                            icon: Icons.timer_rounded,
                            label: '5 Minuten',
                            meta: 'Best of',
                            onTap: () =>
                                _startQuiz(GameConfig.quizRushFiveMinutes),
                          ),
                          _OptionAction(
                            icon: Icons.favorite_rounded,
                            label: 'Endless',
                            meta: '3 Leben',
                            onTap: () => _startQuiz(GameConfig.quizRushEndless),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        iconAsset: 'assets/icons/modes/classic.webp',
                        backgroundAsset: 'assets/images/modes/classic.webp',
                        eyebrow: 'Set',
                        title: 'Klassik',
                        description:
                            'Feste Fragensets für konzentrierte Sessions ohne Zeitdruck.',
                        accent: AppColors.sage,
                        children: [
                          for (final count in const [10, 15, 20])
                            _OptionAction(
                              icon: Icons.format_list_numbered_rounded,
                              label: '$count Fragen',
                              meta: _inputStyle.shortLabel,
                              onTap: () => _startQuiz(
                                GameConfig(
                                  mode: GameMode.classic,
                                  questionCount: count,
                                  inputStyle: _inputStyle,
                                  perQuestionTimeLimit: Duration.zero,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        iconAsset: 'assets/icons/modes/duel.webp',
                        backgroundAsset: 'assets/images/modes/duel.webp',
                        eyebrow: 'Versus',
                        title: 'Duell',
                        description:
                            'Tritt live gegen eine Freundin an. Wähle deinen '
                            'eigenen Spielstil.',
                        accent: AppColors.plum,
                        children: [
                          _OptionAction(
                            icon: Icons.add_rounded,
                            label: 'Lobby eröffnen',
                            meta: 'Code teilen',
                            onTap: () => context.push('/duel', extra: 0),
                          ),
                          _OptionAction(
                            icon: Icons.login_rounded,
                            label: 'Beitreten',
                            meta: '6-Zeichen-Code',
                            onTap: () => context.push('/duel', extra: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        iconAsset: 'assets/icons/modes/crossword.webp',
                        backgroundAsset: 'assets/images/modes/crossword.webp',
                        eyebrow: 'Daily-ready',
                        title: 'Kreuzworträtsel',
                        description:
                            'Teste dein Wissen mit herausfordernden Rätseln.',
                        accent: AppColors.dustyTeal,
                        children: [
                          _OptionAction(
                            icon: Icons.keyboard_alt_rounded,
                            label: 'Rätsel starten',
                            meta: 'Eingabe',
                            onTap: () => context.push('/crossword'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _UtilityRail(
                        onLeaderboard: () => context.push('/leaderboard'),
                      ),
                    ].animate(interval: 45.ms).fadeIn(duration: 280.ms).moveY(
                          begin: 10,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz(GameConfig config) {
    final adjusted = config.copyWith(
      inputStyle: _inputStyle,
      difficultyMin: _band.min,
      difficultyMax: _band.max,
      perQuestionTimeLimit: config.perQuestionTimeLimit == Duration.zero
          ? Duration.zero
          : _questionLimit,
    );
    context.push('/play', extra: adjusted);
  }

  void _setInputStyle(AnswerInputStyle value) {
    setState(() {
      _inputStyle = value;
      _loadedFromProfile = true;
    });
    ref.read(profileNotifierProvider.notifier).setPreferredInputStyle(value);
  }

  void _setBand(DifficultyBand value) {
    setState(() {
      _band = value;
      _loadedFromProfile = true;
    });
    ref.read(profileNotifierProvider.notifier).setDifficultyBand(value);
  }
}

class _HomeIntroPanel extends StatelessWidget {
  const _HomeIntroPanel();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.divider),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        palette.page,
                        palette.page.withValues(alpha: 0.94),
                        palette.parchment.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ELEUTHERIA',
                            style: AppTypography.eyebrow(palette.gold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Spielmodus wählen',
                            style: AppTypography.serif(
                              fontSize: compact ? 28 : 32,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Schnelle Runden, klassische Sets, Duelle und Kreuzworträtsel. Antwortart und Schwierigkeit unten anpassen.',
                            maxLines: compact ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sans(
                              fontSize: 13.5,
                              height: 1.42,
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 12),
                      const BrandSeal(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

int _unlockedAchievementCount(PlayerProfile? profile) {
  if (profile == null) return 0;
  return kAchievements
      .where((a) => a.isAnyUnlocked(profile.unlockedAchievements))
      .length;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.displayName,
    required this.streakDays,
    required this.rankTitle,
    required this.level,
    required this.unlockedCount,
    required this.totalCount,
  });

  final String displayName;
  final int streakDays;
  final String rankTitle;
  final int level;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: const _HeaderAppIcon(size: 58),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guten Tag,',
                        style: AppTypography.eyebrow(palette.gold),),
                    const SizedBox(height: 3),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.serif(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              _StreakBadge(days: streakDays),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Einstellungen',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RankChip(
            rankTitle: rankTitle,
            level: level,
            unlockedCount: unlockedCount,
            totalCount: totalCount,
          ),
        ],
      ),
    );
  }
}

/// Tappable rank summary leading into the achievement gallery.
class _RankChip extends StatelessWidget {
  const _RankChip({
    required this.rankTitle,
    required this.level,
    required this.unlockedCount,
    required this.totalCount,
  });

  final String rankTitle;
  final int level;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/achievements'),
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: palette.gold.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/icons/achievements.webp',
                  width: 32,
                  height: 32,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                rankTitle,
                style: AppTypography.serif(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                  letterSpacing: -0.1,
                ),
              ),
              Text(
                '  ·  Stufe $level',
                style: TextStyle(color: palette.inkMuted, fontSize: 12.5),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 14, color: palette.divider),
              const SizedBox(width: 10),
              Text(
                '$unlockedCount / $totalCount',
                style: AppTypography.serif(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.gold,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: palette.inkMuted,),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAppIcon extends StatelessWidget {
  const _HeaderAppIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.page.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: palette.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Image.asset(
          'assets/icons/app_icon.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _AnswerStyleSwitch extends StatelessWidget {
  const _AnswerStyleSwitch({
    required this.value,
    required this.onChanged,
  });

  final AnswerInputStyle value;
  final ValueChanged<AnswerInputStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANTWORTART', style: AppTypography.eyebrow(palette.inkMuted)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AnswerInputStyle>(
              showSelectedIcon: false,
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.single),
              segments: const [
                ButtonSegment(
                  value: AnswerInputStyle.multipleChoice,
                  icon: Icon(Icons.checklist_rounded),
                  label: Text('Multiple Choice'),
                ),
                ButtonSegment(
                  value: AnswerInputStyle.letterbox,
                  icon: Icon(Icons.keyboard_alt_rounded),
                  label: Text('Eingabe'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBandSwitch extends StatelessWidget {
  const _DifficultyBandSwitch({
    required this.value,
    required this.onChanged,
  });

  final DifficultyBand value;
  final ValueChanged<DifficultyBand> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCHWIERIGKEIT · ${value.subtitle.toUpperCase()}',
            style: AppTypography.eyebrow(palette.inkMuted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<DifficultyBand>(
              showSelectedIcon: false,
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.single),
              segments: const [
                ButtonSegment(
                  value: DifficultyBand.einstieg,
                  label: Text('Einstieg'),
                ),
                ButtonSegment(
                  value: DifficultyBand.salon,
                  label: Text('Salon'),
                ),
                ButtonSegment(
                  value: DifficultyBand.meisterpruefung,
                  label: Text('Meister'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.iconAsset,
    required this.backgroundAsset,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accent,
    required this.children,
  });

  final String iconAsset;
  final String backgroundAsset;
  final String eyebrow;
  final String title;
  final String description;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // "Buchrücken" — vertikaler Akzent-Streifen links.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: accent),
          ),
          Positioned(
            top: 0,
            right: -18,
            bottom: 0,
            width: 170,
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              filterQuality: FilterQuality.low,
            ),
          ),
          Positioned.fill(
            left: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    palette.page,
                    palette.page.withValues(alpha: 0.98),
                    palette.page.withValues(alpha: 0.88),
                    palette.page.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModeAssetIcon(asset: iconAsset, tint: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow.toUpperCase(),
                            style: AppTypography.eyebrow(accent),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: AppTypography.serif(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: AppTypography.sans(
                              fontSize: 13,
                              height: 1.38,
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: children,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeAssetIcon extends StatelessWidget {
  const _ModeAssetIcon({required this.asset, this.tint});

  final String asset;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final borderColor = tint?.withValues(alpha: 0.45) ?? palette.divider;
    return Container(
      width: 46,
      height: 46,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor, width: tint == null ? 1 : 1.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _OptionAction extends StatelessWidget {
  const _OptionAction({
    required this.icon,
    required this.label,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 140, minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: palette.parchment.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: palette.burgundy),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: AppTypography.sans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: palette.inkMuted,
                    ),
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

class _UtilityRail extends StatelessWidget {
  const _UtilityRail({required this.onLeaderboard});

  final VoidCallback onLeaderboard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLeaderboard,
        icon: const Icon(Icons.leaderboard_rounded),
        label: const Text('Rangliste'),
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
    final resolvedIconColor =
        iconColor ?? (accent ? palette.gold : palette.burgundy);
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
              color: accent
                  ? palette.gold.withValues(alpha: 0.55)
                  : palette.divider,
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
