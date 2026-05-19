import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/answer_input_style.dart';
import '../../data/models/game_session.dart';
import '../../shared/widgets/achievement_unlock_overlay.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../letterbox/widgets/letterbox_input.dart';
import 'game_session_controller.dart';
import 'widgets/answer_option_button.dart';
import 'widgets/question_prompt_card.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/reveal_panel.dart';

/// The main quiz playthrough — one screen for all solo modes.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.config});

  final GameConfig config;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  Timer? _ticker;
  double _timerProgress = 0.0;
  DateTime _startedAt = DateTime.now();
  DateTime _sessionStartedAt = DateTime.now();
  bool _navigatingAway = false;
  String _typed = '';
  final GlobalKey<LetterboxInputState> _letterboxKey = GlobalKey();

  static const _letters = ['A', 'B', 'C', 'D'];

  bool get _isLetterbox =>
      widget.config.inputStyle == AnswerInputStyle.letterbox;

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _resetTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _ticker?.cancel();
    if (widget.config.mode == GameMode.practice) return;
    final limit =
        widget.config.sessionTimeLimit ?? widget.config.perQuestionTimeLimit;
    if (limit <= Duration.zero) {
      _timerProgress = 0;
      return;
    }
    _startedAt = widget.config.sessionTimeLimit == null
        ? DateTime.now()
        : _sessionStartedAt;
    _ticker = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final elapsed = DateTime.now().difference(_startedAt);
      final progress = elapsed.inMilliseconds / limit.inMilliseconds;
      if (progress >= 1.0) {
        _ticker?.cancel();
        if (widget.config.sessionTimeLimit == null) {
          _autoSubmit();
        } else {
          _finishFromTimer();
        }
      }
      if (mounted) {
        setState(() => _timerProgress = progress.clamp(0.0, 1.0).toDouble());
      }
    });
  }

  void _finishFromTimer() {
    if (_navigatingAway || !mounted) return;
    _navigatingAway = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _finishSession();
    });
  }

  void _autoSubmit() {
    final notifier = ref.read(gameSessionProvider(widget.config).notifier);
    final st = ref.read(gameSessionProvider(widget.config));
    if (!st.revealed) {
      if (_isLetterbox) {
        notifier.submitTypedAnswer(_typed);
      } else {
        notifier.submit(overrideIndex: -1);
      }
    }
  }

  void _submitLetterbox(WidgetRef ref) {
    _stopQuestionTimer();
    ref
        .read(gameSessionProvider(widget.config).notifier)
        .submitTypedAnswer(_typed);
  }

  void _stopQuestionTimer() {
    if (widget.config.sessionTimeLimit == null) {
      _ticker?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameSessionProvider(widget.config));
    final notifier = ref.read(gameSessionProvider(widget.config).notifier);
    final session = state.session;

    if (session.isFinished && !_navigatingAway) {
      _navigatingAway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishSession();
      });
    }
    if (notifier.suddenDeathFailed && !_navigatingAway) {
      _navigatingAway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishSession();
      });
    }
    if (notifier.rushOutOfLives && !_navigatingAway) {
      _navigatingAway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishSession();
      });
    }

    final question = session.currentQuestion;
    if (question == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final palette = context.palette;

    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _confirmExit,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: QuizProgressBar(
                            progress: _sessionProgress(state),
                            timerProgress:
                                state.revealed ? null : _timerProgress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!state.revealed)
                          _PowerUpButton(
                            symbol: '½',
                            tooltip: _fiftyFiftyTooltip(notifier),
                            enabled: notifier.canUseFiftyFifty,
                            onPressed: notifier.useFiftyFifty,
                          ),
                      ],
                    ),
                    _SessionMetaBar(
                      config: widget.config,
                      answered: state.session.answers.length,
                      correct: state.session.correctCount,
                      total: state.session.questions.length,
                      livesRemaining: notifier.livesRemaining,
                      timeRemaining: _timeRemaining(),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            QuestionPromptCard(
                              key: ValueKey(question.id),
                              question: question,
                              questionNumber: state.session.currentIndex + 1,
                              totalQuestions: state.session.questions.length,
                            )
                                .animate(key: ValueKey('p${question.id}'))
                                .fadeIn(duration: 280.ms)
                                .moveY(
                                  begin: 12,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 22),
                            if (_isLetterbox)
                              LetterboxInput(
                                key: _letterboxKey,
                                target: question.correctAnswer,
                                revealedIndices: state.revealedLetterIndices,
                                revealed: state.revealed,
                                wasCorrect: state.session.answers.isEmpty
                                    ? false
                                    : state.session.answers.last.wasCorrect,
                                onChanged: (v) => _typed = v,
                                onSubmitted: (_) => _submitLetterbox(ref),
                              )
                            else
                              ...List.generate(question.options.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AnswerOptionButton(
                                    label: question.options[i],
                                    optionLetter: _letters[i],
                                    onTap: () => notifier.selectOption(i),
                                    isSelected: state.selectedIndex == i,
                                    isCorrect: i == question.correctIndex,
                                    isRevealed: state.revealed,
                                    isEliminated:
                                        state.eliminatedIndices.contains(i),
                                  ),
                                )
                                    .animate(
                                      key: ValueKey('o${question.id}_$i'),
                                      delay: (60 * i).ms,
                                    )
                                    .fadeIn(duration: 240.ms)
                                    .moveX(
                                      begin: 12,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    );
                              }),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!state.revealed)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: _SubmitBar(
                    enabled: _isLetterbox
                        ? _typed.isNotEmpty
                        : state.selectedIndex >= 0,
                    label: _isLetterbox ? 'Lösen' : 'Antwort bestätigen',
                    onPressed: () {
                      _stopQuestionTimer();
                      if (_isLetterbox) {
                        _submitLetterbox(ref);
                      } else {
                        notifier.submit();
                      }
                    },
                  ),
                ),
              if (state.revealed)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RevealPanel(
                    question: question,
                    wasCorrect: state.session.answers.last.wasCorrect,
                    points: state.session.answers.last.points,
                    onContinue: () {
                      notifier.next();
                      _typed = '';
                      _letterboxKey.currentState?.reset();
                      if (!state.session.isFinished) _resetTimer();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      backgroundColor: palette.parchment,
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        return AlertDialog(
          backgroundColor: palette.page,
          title: const Text('Quiz beenden?'),
          content: const Text(
            'Dein bisheriger Fortschritt geht verloren.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Weiterspielen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Beenden'),
            ),
          ],
        );
      },
    );
    if ((shouldExit ?? false) && mounted) {
      context.pop();
    }
  }

  Future<void> _finishSession() async {
    _ticker?.cancel();
    final state = ref.read(gameSessionProvider(widget.config));
    final controller = ref.read(gameSessionProvider(widget.config).notifier);
    final session = state.session;

    final xp = controller.xpForSession();

    final unlocked =
        await ref.read(profileNotifierProvider.notifier).applySessionResult(
              session: session,
              xpGained: xp,
            );

    if (!mounted) return;

    // Celebrate freshly-unlocked tiers in front of the result screen so the
    // moment isn't buried under stats. The overlay returns once the player
    // has dismissed the last sheet.
    if (unlocked.isNotEmpty) {
      await AchievementUnlockOverlay.show(context, unlocked);
      if (!mounted) return;
    }

    context.pushReplacement('/result', extra: {
      'session': session,
      'xpGained': xp,
      'unlockedAchievements': unlocked,
    },);
  }

  double _sessionProgress(GameSessionState state) {
    final sessionLimit = widget.config.sessionTimeLimit;
    if (sessionLimit != null) {
      return _timerProgress;
    }
    if (state.session.questions.isEmpty) return 0;
    return state.session.currentIndex / state.session.questions.length;
  }

  Duration? _timeRemaining() {
    final limit = widget.config.sessionTimeLimit;
    if (limit == null) return null;
    final remaining = limit - DateTime.now().difference(_sessionStartedAt);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _fiftyFiftyTooltip(GameSessionController notifier) {
    final remaining = notifier.fiftyFiftyRemaining;
    final suffix = remaining == null ? 'immer verfügbar' : '$remaining übrig';
    if (_isLetterbox) return '50/50: Buchstaben aufdecken ($suffix)';
    return '50/50: falsche Antworten entfernen ($suffix)';
  }
}

class _SessionMetaBar extends StatelessWidget {
  const _SessionMetaBar({
    required this.config,
    required this.answered,
    required this.correct,
    required this.total,
    required this.livesRemaining,
    required this.timeRemaining,
  });

  final GameConfig config;
  final int answered;
  final int correct;
  final int total;
  final int? livesRemaining;
  final Duration? timeRemaining;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isRush = config.mode == GameMode.quizRush;
    final label = isRush
        ? config.sessionLabel ?? 'Quiz-Rush'
        : '${answered.clamp(0, total)} / $total';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _MetaPill(
            icon: Icons.bolt_rounded,
            label: label,
            color: isRush ? palette.burgundy : palette.inkMuted,
          ),
          const SizedBox(width: 8),
          _MetaPill(
            icon: config.inputStyle == AnswerInputStyle.multipleChoice
                ? Icons.checklist_rounded
                : Icons.keyboard_alt_rounded,
            label: config.inputStyle.shortLabel,
            color: palette.inkMuted,
          ),
          const Spacer(),
          if (timeRemaining != null)
            _MetaPill(
              icon: Icons.timer_rounded,
              label: _formatDuration(timeRemaining!),
              color: palette.incorrect,
            )
          else if (livesRemaining != null)
            _MetaPill(
              icon: Icons.favorite_rounded,
              label: '$livesRemaining',
              color: palette.incorrect,
            )
          else
            _MetaPill(
              icon: Icons.done_rounded,
              label: '$correct richtig',
              color: palette.correct,
            ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final seconds = d.inSeconds.clamp(0, 24 * 60 * 60).toInt();
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.sans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.enabled,
    required this.onPressed,
    this.label = 'Antwort bestätigen',
  });

  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: enabled ? onPressed : null,
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  const _PowerUpButton({
    required this.symbol,
    required this.tooltip,
    required this.onPressed,
    required this.enabled,
  });

  final String symbol;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? palette.gold.withValues(alpha: 0.15)
                : palette.parchment,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? palette.gold : palette.divider,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            symbol,
            style: AppTypography.serif(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: enabled ? palette.gold : palette.inkMuted,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
