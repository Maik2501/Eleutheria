import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/game_session.dart';
import '../../data/services/achievement_engine.dart';
import '../../shared/widgets/chapter_heading.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/wax_seal.dart';

/// Final summary after a session.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.session,
    required this.xpGained,
    required this.unlockedAchievements,
  });

  final GameSession session;
  final int xpGained;
  final List<UnlockedTier> unlockedAchievements;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    final flawless =
        widget.session.correctCount == widget.session.questions.length;
    if (flawless) _confetti.play();

    // Fire-and-forget: Score an Supabase übermitteln, falls die Session
    // auf ein Leaderboard gehört (Repository entscheidet das selbst).
    // Fehler bleiben still — die Result-UI soll nicht ins Stolpern kommen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSubmitScore());
  }

  Future<void> _maybeSubmitScore() async {
    final repo = ref.read(scoreRepositoryProvider);
    final profile = ref.read(profileNotifierProvider).value;
    if (repo == null || profile == null) return;
    await repo.maybeSubmit(
      session: widget.session,
      profile: profile,
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final correct = widget.session.correctCount;
    final total = widget.session.mode == GameMode.quizRush
        ? widget.session.answers.length
        : widget.session.questions.length;
    final score = widget.session.totalScore;
    final percent = total == 0 ? 0 : (correct / total * 100).round();

    final headline = _headlineFor(percent);
    final unlocked = widget.unlockedAchievements;

    return Scaffold(
      body: ParchmentBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: WaxSeal(
                        symbol: percent >= 80
                            ? '✪'
                            : percent >= 50
                                ? '✦'
                                : '✧',
                        size: 86,
                      ),
                    ).animate().scale(
                          duration: 520.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1, 1),
                        ),
                    const SizedBox(height: 22),
                    ChapterHeading(
                      eyebrow: widget.session.mode.title,
                      title: headline,
                      alignment: CrossAxisAlignment.center,
                      subtitle: _subtitle(correct, total),
                    ),
                    const SizedBox(height: 28),
                    const DecorativeRule(),
                    const SizedBox(height: 28),
                    _ScoreRow(score: score, xp: widget.xpGained),
                    const SizedBox(height: 28),
                    _AnswerHistogram(session: widget.session),
                    if (unlocked.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'NEU FREIGESCHALTET',
                        textAlign: TextAlign.center,
                        style: AppTypography.eyebrow(palette.gold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var i = 0; i < unlocked.length; i++)
                            _AchievementChip(unlock: unlocked[i])
                                .animate(delay: (90 * i).ms)
                                .scale(
                                  begin: const Offset(0.6, 0.6),
                                  end: const Offset(1, 1),
                                  duration: 420.ms,
                                  curve: Curves.elasticOut,
                                )
                                .fadeIn(duration: 280.ms),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Erneut spielen',
                      icon: Icons.replay_rounded,
                      onPressed: () => context.pushReplacement('/'),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'Zurück zum Menü',
                      onPressed: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.06,
                numberOfParticles: 16,
                gravity: 0.25,
                colors: [
                  palette.gold,
                  palette.burgundy,
                  AppColors.terracotta,
                  palette.correct,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headlineFor(int percent) {
    if (percent == 100) return 'Tabula perfecta.';
    if (percent >= 80) return 'Bravissimo.';
    if (percent >= 60) return 'Solide Lektüre.';
    if (percent >= 40) return 'Mehr Lektüre wartet.';
    return 'Ein nächstes Kapitel.';
  }

  String _subtitle(int correct, int total) => switch (widget.session.mode) {
        GameMode.suddenDeath => '$correct Fragen am Stück.',
        GameMode.quizRush =>
          '$correct richtig in ${widget.session.answers.length} Versuchen.',
        _ => '$correct von $total richtig.',
      };
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.score, required this.xp});
  final int score;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget col(String label, String value, {Color? color}) => Expanded(
          child: Column(
            children: [
              Text(label.toUpperCase(),
                  style: AppTypography.eyebrow(palette.inkMuted),),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTypography.serif(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: color ?? palette.ink,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          col('Punkte', '$score'),
          Container(
            width: 1,
            height: 50,
            color: palette.divider,
          ),
          col('Erfahrung', '+$xp', color: palette.gold),
        ],
      ),
    );
  }
}

class _AnswerHistogram extends StatelessWidget {
  const _AnswerHistogram({required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verlauf', style: AppTypography.eyebrow(palette.inkMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final a in session.answers)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 8,
                    decoration: BoxDecoration(
                      color: a.wasCorrect
                          ? palette.correct
                          : palette.incorrect.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.unlock});
  final UnlockedTier unlock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = unlock.tier.level.tint;
    return Container(
      width: 144,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: tint.withValues(alpha: 0.65), width: 1.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          WaxSeal(
            symbol: unlock.tier.symbol,
            size: 38,
            color: tint,
            assetPath: unlock.achievement.assetPathOf(unlock.tier),
          ),
          const SizedBox(height: 10),
          Text(
            unlock.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.serif(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: palette.ink,
              height: 1.25,
            ),
          ),
          if (unlock.achievement.isMultiTier) ...[
            const SizedBox(height: 4),
            Text(
              unlock.tier.level.label.toUpperCase(),
              style: AppTypography.eyebrow(tint).copyWith(letterSpacing: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
