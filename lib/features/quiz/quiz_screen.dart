import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/game_session.dart';
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
  bool _navigatingAway = false;
  String _typed = '';
  final GlobalKey<LetterboxInputState> _letterboxKey = GlobalKey();

  static const _letters = ['A', 'B', 'C', 'D'];

  bool get _isLetterbox =>
      widget.config.inputStyle == AnswerInputStyle.letterbox;

  @override
  void initState() {
    super.initState();
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
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final elapsed = DateTime.now().difference(_startedAt);
      final progress =
          elapsed.inMilliseconds / widget.config.perQuestionTimeLimit.inMilliseconds;
      if (progress >= 1.0) {
        _ticker?.cancel();
        _autoSubmit();
      }
      setState(() => _timerProgress = progress.clamp(0.0, 1.0));
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
    _ticker?.cancel();
    ref.read(gameSessionProvider(widget.config).notifier)
        .submitTypedAnswer(_typed);
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
                            progress: state.session.currentIndex /
                                state.session.questions.length,
                            timerProgress:
                                state.revealed ? null : _timerProgress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!state.revealed)
                          _PowerUpButton(
                            symbol: '½',
                            tooltip: '50/50',
                            enabled: state.eliminatedIndices.isEmpty,
                            onPressed: notifier.useFiftyFifty,
                          ),
                      ],
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
                              questionNumber:
                                  state.session.currentIndex + 1,
                              totalQuestions:
                                  state.session.questions.length,
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
                                ).animate(
                                  key: ValueKey('o${question.id}_$i'),
                                  delay: (60 * i).ms,
                                ).fadeIn(duration: 240.ms).moveX(
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
                      _ticker?.cancel();
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
    final state = ref.read(gameSessionProvider(widget.config));
    final controller =
        ref.read(gameSessionProvider(widget.config).notifier);
    final session = state.session;

    final xp = controller.xpForSession();
    final isClassic = session.mode == GameMode.classic;
    final flawless =
        isClassic && session.correctCount == session.questions.length;
    final suddenStreak = session.mode == GameMode.suddenDeath
        ? session.correctCount
        : 0;

    final unlocked =
        await ref.read(profileNotifierProvider.notifier).applySessionResult(
              xpGained: xp,
              correctAnswers: session.correctCount,
              suddenDeathStreak: suddenStreak,
              flawlessClassic: flawless,
              wonDuel: false,
            );

    if (!mounted) return;
    context.pushReplacement('/result', extra: {
      'session': session,
      'xpGained': xp,
      'unlockedAchievements': unlocked,
    });
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
            color: enabled ? palette.gold.withValues(alpha: 0.15) : palette.parchment,
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
