import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/question.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/wax_seal.dart';
import '../quiz/widgets/answer_option_button.dart';
import '../quiz/widgets/question_prompt_card.dart';
import 'duel_lobby_screen.dart';
import 'duel_repository.dart';

/// Live duel screen — host & guest share the same questions, race per question.
class DuelMatchScreen extends ConsumerStatefulWidget {
  const DuelMatchScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<DuelMatchScreen> createState() => _DuelMatchScreenState();
}

class _DuelMatchScreenState extends ConsumerState<DuelMatchScreen> {
  static const _letters = ['A', 'B', 'C', 'D'];

  StreamSubscription<DuelMatch>? _matchSub;
  StreamSubscription<List<DuelAnswer>>? _answersSub;

  DuelMatch? _match;
  List<Question> _questions = const [];
  List<DuelAnswer> _allAnswers = const [];

  int _currentIndex = 0;
  int _selectedIndex = -1;
  bool _revealed = false;
  DateTime _questionStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    final repo = ref.read(duelRepositoryProvider);
    final qRepo = ref.read(questionRepositoryProvider);
    if (repo == null) return;
    _matchSub = repo.watchDuel(widget.code).listen((m) {
      setState(() {
        _match = m;
        _questions = repo.resolveQuestions(
          m.questionSeed,
          questions: qRepo,
          count: m.questionCount,
        );
      });
    });
    _answersSub = repo.watchAnswers(widget.code).listen((rows) {
      setState(() => _allAnswers = rows);
    });
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    _answersSub?.cancel();
    super.dispose();
  }

  String? get _meId => ref.read(profileNotifierProvider).value?.id;

  String? get _opponentId {
    final m = _match;
    final me = _meId;
    if (m == null || me == null) return null;
    return m.hostId == me ? m.guestId : m.hostId;
  }

  List<DuelAnswer> _answersFor(String? playerId) =>
      playerId == null ? const [] : _allAnswers.where((a) => a.playerId == playerId).toList();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final m = _match;

    if (m == null || _questions.isEmpty) {
      return Scaffold(
        body: ParchmentBackground(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (m.status == DuelStatus.waiting) {
      return _WaitingScaffold(code: m.code);
    }

    final myAnswers = _answersFor(_meId);
    final oppAnswers = _answersFor(_opponentId);

    final currentIndex = myAnswers.length.clamp(0, _questions.length - 1);
    final allDone = myAnswers.length >= _questions.length &&
        oppAnswers.length >= _questions.length;

    if (allDone) return _buildSummary(myAnswers, oppAnswers);

    final question = _questions[currentIndex];
    if (currentIndex != _currentIndex) {
      // Advanced — reset per-question UI state.
      _currentIndex = currentIndex;
      _selectedIndex = -1;
      _revealed = false;
      _questionStartedAt = DateTime.now();
    }

    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                _DuelHeader(
                  myCorrect: myAnswers.where((a) => a.wasCorrect).length,
                  oppCorrect: oppAnswers.where((a) => a.wasCorrect).length,
                  myDone: myAnswers.length,
                  oppDone: oppAnswers.length,
                  total: _questions.length,
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        QuestionPromptCard(
                          key: ValueKey(question.id),
                          question: question,
                          questionNumber: currentIndex + 1,
                          totalQuestions: _questions.length,
                        ),
                        const SizedBox(height: 18),
                        ...List.generate(question.options.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AnswerOptionButton(
                              label: question.options[i],
                              optionLetter: _letters[i],
                              onTap: () {
                                if (_revealed) return;
                                HapticFeedback.selectionClick();
                                setState(() => _selectedIndex = i);
                              },
                              isSelected: _selectedIndex == i,
                              isCorrect: i == question.correctIndex,
                              isRevealed: _revealed,
                              isEliminated: false,
                            ),
                          );
                        }),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PrimaryButton(
            label: _revealed ? 'Warte auf Mitspielerin…' : 'Antwort senden',
            onPressed: _revealed || _selectedIndex < 0
                ? null
                : () => _submit(question, currentIndex),
          ),
        ),
      ),
      backgroundColor: palette.parchment,
    );
  }

  Future<void> _submit(Question q, int index) async {
    final me = _meId;
    final repo = ref.read(duelRepositoryProvider);
    if (me == null || repo == null) return;

    final wasCorrect = _selectedIndex == q.correctIndex;
    final dt = DateTime.now().difference(_questionStartedAt);
    // Speed scoring: faster correct answer = more points.
    final base = wasCorrect ? 100 + (q.difficulty - 1) * 25 : 0;
    final bonus = wasCorrect
        ? ((20000 - dt.inMilliseconds).clamp(0, 20000) / 20000 * 100).round()
        : 0;
    final pts = base + bonus;

    setState(() => _revealed = true);
    HapticFeedback.mediumImpact();

    await repo.submitAnswer(
      code: widget.code,
      playerId: me,
      questionIndex: index,
      selectedIndex: _selectedIndex,
      wasCorrect: wasCorrect,
      timeTaken: dt,
      points: pts,
    );
  }

  Widget _buildSummary(List<DuelAnswer> me, List<DuelAnswer> opp) {
    final palette = context.palette;
    final myScore = me.fold<int>(0, (s, a) => s + a.points);
    final oppScore = opp.fold<int>(0, (s, a) => s + a.points);
    final iWin = myScore > oppScore;
    final tie = myScore == oppScore;

    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: WaxSeal(
                    symbol: tie ? '∞' : (iWin ? '✪' : '✦'),
                    size: 86,
                    color: tie ? palette.gold : (iWin ? palette.gold : palette.burgundy),
                  ).animate().scale(
                        duration: 520.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  tie
                      ? 'Unentschieden'
                      : iWin
                          ? 'Gewonnen.'
                          : 'Knapp daneben.',
                  textAlign: TextAlign.center,
                  style: AppTypography.serif(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ScorePillar(
                        label: 'Du',
                        value: myScore,
                        highlight: iWin,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ScorePillar(
                        label: 'Mitspielerin',
                        value: oppScore,
                        highlight: !iWin && !tie,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Zurück zum Menü',
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingScaffold extends StatelessWidget {
  const _WaitingScaffold({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Lobby')),
      body: ParchmentBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Teile diesen Code',
                  style: AppTypography.eyebrow(palette.gold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(
                    color: palette.page,
                    border: Border.all(color: palette.divider),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    code,
                    style: AppTypography.serif(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: palette.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Warte auf Mitspielerin…',
                  style: TextStyle(color: palette.inkMuted, fontSize: 14),
                ),
                const SizedBox(height: 32),
                IconButton.filled(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code kopiert.')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DuelHeader extends StatelessWidget {
  const _DuelHeader({
    required this.myCorrect,
    required this.oppCorrect,
    required this.myDone,
    required this.oppDone,
    required this.total,
  });

  final int myCorrect;
  final int oppCorrect;
  final int myDone;
  final int oppDone;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget pill(String label, int correct, int done, {required bool me}) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: palette.page,
              border: Border.all(
                color: me ? palette.burgundy : palette.divider,
                width: me ? 1.4 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(label, style: AppTypography.eyebrow(palette.inkMuted)),
                const Spacer(),
                Text(
                  '$correct/$total',
                  style: AppTypography.serif(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done >= total ? palette.correct : palette.gold,
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        pill('DU', myCorrect, myDone, me: true),
        const SizedBox(width: 10),
        pill('MITSPIELERIN', oppCorrect, oppDone, me: false),
      ],
    );
  }
}

class _ScorePillar extends StatelessWidget {
  const _ScorePillar({
    required this.label,
    required this.value,
    required this.highlight,
  });

  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(
          color: highlight ? palette.gold : palette.divider,
          width: highlight ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.eyebrow(palette.inkMuted),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: AppTypography.serif(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: highlight ? palette.gold : palette.ink,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
