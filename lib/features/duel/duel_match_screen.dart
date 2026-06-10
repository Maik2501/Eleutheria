import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/answer_input_style.dart';
import '../../data/models/duel_config.dart';
import '../../data/models/game_session.dart';
import '../../data/models/question.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/wax_seal.dart';
import '../letterbox/answer_normalization.dart';
import '../letterbox/widgets/letterbox_input.dart';
import '../quiz/widgets/answer_option_button.dart';
import '../quiz/widgets/question_prompt_card.dart';
import 'duel_lobby_screen.dart';
import 'duel_repository.dart';

/// Live duel — handles both modes (race + parallel) on a shared timer.
class DuelMatchScreen extends ConsumerStatefulWidget {
  const DuelMatchScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<DuelMatchScreen> createState() => _DuelMatchScreenState();
}

class _DuelMatchScreenState extends ConsumerState<DuelMatchScreen> {
  static const _letters = ['A', 'B', 'C', 'D'];

  /// Race-mode post-round breathing room. After a round resolves (someone
  /// got it right, or every alive player has answered wrong), the question
  /// stays frozen this long while both players see who took it, then the
  /// next question slides in. The shared session timer is paused during
  /// this window so it doesn't punish them for the celebration.
  static const _postRoundPause = Duration(seconds: 3);

  /// Parallel-mode local reveal window. Each player gets a brief
  /// "Richtig/Falsch"-Einblendung over the answer area after submitting,
  /// before the next question rolls in. Only affects the local view —
  /// the opponent runs at their own pace.
  static const _parallelFeedbackDuration = Duration(milliseconds: 1200);

  StreamSubscription<DuelMatch>? _matchSub;
  StreamSubscription<List<DuelAnswer>>? _answersSub;
  Timer? _ticker;

  DuelMatch? _match;
  List<Question> _questions = const [];
  List<DuelAnswer> _allAnswers = const [];

  int _renderedIndex = -1;
  int _selectedIndex = -1;
  String _typed = '';
  DateTime _questionStartedAt = DateTime.now();
  final GlobalKey<LetterboxInputState> _letterboxKey = GlobalKey();
  bool _finalized = false;

  /// Once-Flag: XP/Achievements für dieses Duell wurden bereits verbucht.
  /// Der Summary wird vom 250-ms-Ticker ständig neu gebaut — ohne das Flag
  /// würde jeder Rebuild erneut XP vergeben (F1).
  bool _resultApplied = false;

  // Show a brief splash when we transition from waiting → playing.
  bool _showConnectSplash = false;
  DuelStatus? _prevStatus;

  // Presence-tracking: detect when the opponent's tab disconnects.
  RealtimeChannel? _presence;
  Set<String> _presentUserIds = {};
  DateTime? _opponentLostAt;
  bool _opponentDisconnected = false;
  static const _disconnectGracePeriod = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _subscribe();
    _setupPresence();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  void _setupPresence() {
    final client = Supabase.instance.client;
    final me = client.auth.currentUser?.id;
    if (me == null) return;
    final channel = client.channel(
      'duel:${widget.code}',
      opts: RealtimeChannelConfig(key: me),
    );
    channel.onPresenceSync((_) {
      if (!mounted) return;
      final state = channel.presenceState();
      final ids = <String>{};
      for (final s in state) {
        for (final p in s.presences) {
          final uid = (p.payload['user_id'] as String?) ?? p.presenceRef;
          ids.add(uid);
        }
      }
      setState(() => _presentUserIds = ids);
    });
    channel.subscribe((status, _) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.track({'user_id': me});
      }
    });
    _presence = channel;
  }

  void _subscribe() {
    final repo = ref.read(duelRepositoryProvider);
    final qRepo = ref.read(questionRepositoryProvider);
    if (repo == null) return;
    _matchSub = repo.watchDuel(widget.code).listen((m) {
      if (!mounted) return;
      final justConnected =
          _prevStatus == DuelStatus.waiting && m.status == DuelStatus.playing;
      _prevStatus = m.status;
      setState(() {
        _match = m;
        if (_questions.isEmpty && m.status != DuelStatus.waiting) {
          _questions = repo.resolveQuestions(
            m.questionSeed,
            questions: qRepo,
            count: m.questionCount,
            band: m.difficultyBand,
            letterboxFriendlyOnly: m.inputStyle == AnswerInputStyle.letterbox,
          );
        }
        if (justConnected) _showConnectSplash = true;
      });
      if (justConnected) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _showConnectSplash = false);
        });
      }
    });
    _answersSub = repo.watchAnswers(widget.code).listen((rows) {
      if (!mounted) return;
      setState(() => _allAnswers = rows);
    });
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    _answersSub?.cancel();
    _ticker?.cancel();
    final ch = _presence;
    if (ch != null) {
      ch.untrack();
      Supabase.instance.client.removeChannel(ch);
    }
    super.dispose();
  }

  /// Tracks how long the opponent has been missing from the presence channel.
  /// Returns true once the grace period has expired — at that point we treat
  /// the duel as won by us via timeout.
  bool _checkOpponentDisconnected(DuelMatch m) {
    final opp = _opponentId;
    if (opp == null) return false;
    final present = _presentUserIds.contains(opp);
    if (present) {
      _opponentLostAt = null;
      return false;
    }
    _opponentLostAt ??= DateTime.now();
    return DateTime.now().difference(_opponentLostAt!) >=
        _disconnectGracePeriod;
  }

  /// Seconds remaining in the disconnect grace period.
  /// `null` when the opponent is currently present, `0` when the grace
  /// has already expired.
  double? _opponentDisconnectSecondsLeft() {
    final lostAt = _opponentLostAt;
    if (lostAt == null) return null;
    final remaining =
        _disconnectGracePeriod - DateTime.now().difference(lostAt);
    return remaining.isNegative ? 0 : remaining.inMilliseconds / 1000.0;
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _cancelLobby() async {
    final repo = ref.read(duelRepositoryProvider);
    final m = _match;
    if (repo == null || m == null) return;
    await repo.cancel(m.code);
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _confirmSurrender() async {
    final m = _match;
    if (m == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duell aufgeben?'),
        content: const Text(
          'Das Spiel endet sofort. Punkte werden mit dem aktuellen Stand verglichen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Weiterspielen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aufgeben'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final repo = ref.read(duelRepositoryProvider);
      await repo?.finish(m.code);
    }
  }

  // ─── Identity helpers ────────────────────────────────────────────────────

  String? get _meId => ref.read(profileNotifierProvider).value?.id;

  String? get _opponentId {
    final m = _match;
    final me = _meId;
    if (m == null || me == null) return null;
    return m.hostId == me ? m.guestId : m.hostId;
  }

  List<DuelAnswer> _answersFor(String? playerId) => playerId == null
      ? const []
      : _allAnswers.where((a) => a.playerId == playerId).toList();

  // ─── Derived game state ───────────────────────────────────────────────────

  int _livesUsed(List<DuelAnswer> answers) =>
      answers.where((a) => !a.wasCorrect).length;

  bool _alive(DuelMatch m, List<DuelAnswer> answers) {
    final cap = m.livesPerPlayer;
    if (cap == null) return true;
    return _livesUsed(answers) < cap;
  }

  int? _livesRemaining(DuelMatch m, List<DuelAnswer> answers) {
    final cap = m.livesPerPlayer;
    if (cap == null) return null;
    return (cap - _livesUsed(answers)).clamp(0, cap);
  }

  /// Seconds remaining in the shared session, or null if unlimited.
  /// Negative values mean the timer expired. In race mode, post-round
  /// pause windows (3s each) are subtracted from the elapsed time so the
  /// outcome overlay doesn't eat into players' answering budget.
  double? _timeRemainingSeconds(DuelMatch m) {
    final t = m.timeLimitSeconds;
    if (t == null) return null;
    final start = m.startedAt;
    if (start == null) return t.toDouble();
    final rawElapsed = DateTime.now().toUtc().difference(start);
    final effective = rawElapsed - _accumulatedPauseTime(m);
    return t - effective.inMilliseconds / 1000.0;
  }

  /// In race mode, this is the index both players are currently on.
  /// The index only advances once a round has resolved *and* its 3-second
  /// post-round pause has fully elapsed — so during the countdown the
  /// outcome overlay stays in place on both clients.
  int _raceIndex(DuelMatch m, List<DuelAnswer> mine, List<DuelAnswer> theirs) {
    final iAmAlive = _alive(m, mine);
    final oppAlive = _opponentId != null && _alive(m, theirs);
    var i = 0;
    while (i < _questions.length) {
      final atIndex = _allAnswers.where((a) => a.questionIndex == i).toList();
      final anyCorrect = atIndex.any((a) => a.wasCorrect);
      final aliveAndPending = [
        if (iAmAlive && !atIndex.any((a) => a.playerId == _meId)) true,
        if (oppAlive && !atIndex.any((a) => a.playerId == _opponentId)) true,
      ];
      final resolved = anyCorrect || aliveAndPending.isEmpty;
      if (!resolved) break;
      // Resolved — but hold on this index until the pause window elapses.
      if (_isInPostRoundPause(m, i)) break;
      i++;
    }
    return i;
  }

  /// In parallel mode, my own progression is just my answer count — except
  /// while I'm in the local Richtig/Falsch-feedback window: there we hold
  /// on the just-answered question so the reveal can land before the next
  /// question slides in.
  int _parallelIndex(List<DuelAnswer> mine) {
    if (_parallelInFeedback(mine) && mine.isNotEmpty) {
      return mine.length - 1;
    }
    return mine.length;
  }

  /// Whether the local "Richtig/Falsch"-Einblendung for parallel mode is
  /// currently active. True while the most recent answer is younger than
  /// [_parallelFeedbackDuration]. Derived from server timestamps so it
  /// stays consistent across rebuilds.
  bool _parallelInFeedback(List<DuelAnswer> mine) {
    final latest = _myLatestParallelAnswer(mine);
    if (latest == null) return false;
    final age = DateTime.now().toUtc().difference(latest.submittedAt);
    return age < _parallelFeedbackDuration;
  }

  DuelAnswer? _myLatestParallelAnswer(List<DuelAnswer> mine) {
    if (mine.isEmpty) return null;
    DuelAnswer best = mine.first;
    for (final a in mine.skip(1)) {
      if (a.questionIndex > best.questionIndex) best = a;
    }
    return best;
  }

  bool _alreadyAnsweredCurrent(int currentIndex, List<DuelAnswer> mine) {
    return mine.any((a) => a.questionIndex == currentIndex);
  }

  bool _someoneCorrectAt(int index) {
    return _allAnswers.any((a) => a.questionIndex == index && a.wasCorrect);
  }

  // ─── Round-end pause (race mode) ─────────────────────────────────────────

  /// First correct answer at [index] in submission order, or null.
  DuelAnswer? _firstCorrectAt(int index) {
    DuelAnswer? best;
    for (final a in _allAnswers) {
      if (a.questionIndex != index || !a.wasCorrect) continue;
      if (best == null || a.submittedAt.isBefore(best.submittedAt)) best = a;
    }
    return best;
  }

  /// How many players were alive at the *start* of round [index]. Derived
  /// purely from the answer stream so both clients agree.
  int _aliveAtRoundStart(DuelMatch m, int index) {
    if (_opponentId == null) return 1;
    final cap = m.livesPerPlayer;
    if (cap == null) return 2;
    var wrongsMe = 0;
    var wrongsOpp = 0;
    for (final a in _allAnswers) {
      if (a.questionIndex >= index || a.wasCorrect) continue;
      if (a.playerId == _meId) {
        wrongsMe++;
      } else if (a.playerId == _opponentId) {
        wrongsOpp++;
      }
    }
    final iAlive = wrongsMe < cap;
    final oppAlive = wrongsOpp < cap;
    return (iAlive ? 1 : 0) + (oppAlive ? 1 : 0);
  }

  /// Server-side timestamp at which round [index] resolved, or null if it's
  /// still in flight. Resolves on (a) the first correct answer, or (b) once
  /// every alive player has submitted (race ended without a hit).
  DateTime? _roundResolvedAt(DuelMatch m, int index) {
    final atIndex =
        _allAnswers.where((a) => a.questionIndex == index).toList();
    if (atIndex.isEmpty) return null;
    final firstCorrect = _firstCorrectAt(index);
    if (firstCorrect != null) return firstCorrect.submittedAt;
    final aliveCount = _aliveAtRoundStart(m, index);
    if (atIndex.length < aliveCount) return null;
    return atIndex
        .map((a) => a.submittedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// True while the current round at [index] sits inside the 3-second
  /// post-round window. Drives both the outcome overlay and the
  /// session-timer pause.
  bool _isInPostRoundPause(DuelMatch m, int index) {
    final resolvedAt = _roundResolvedAt(m, index);
    if (resolvedAt == null) return false;
    return DateTime.now().toUtc().difference(resolvedAt) < _postRoundPause;
  }

  /// Pause time charged against the shared game clock so far. Each resolved
  /// round contributes up to [_postRoundPause]; an ongoing pause contributes
  /// only its elapsed-so-far portion, so the visible session timer freezes
  /// during the countdown and resumes when it ends.
  Duration _accumulatedPauseTime(DuelMatch m) {
    if (m.mode != DuelMode.race || _allAnswers.isEmpty) return Duration.zero;
    final maxIdx = _allAnswers
        .map((a) => a.questionIndex)
        .reduce((a, b) => a > b ? a : b);
    var total = Duration.zero;
    for (var i = 0; i <= maxIdx; i++) {
      final resolvedAt = _roundResolvedAt(m, i);
      if (resolvedAt == null) continue;
      final age = DateTime.now().toUtc().difference(resolvedAt);
      total += age >= _postRoundPause
          ? _postRoundPause
          : (age.isNegative ? Duration.zero : age);
    }
    return total;
  }

  /// Outcome of the round at [index] for the round-end overlay. Returns
  /// null while the round is still in flight.
  _RoundOutcome? _roundOutcome(DuelMatch m, int index) {
    final resolvedAt = _roundResolvedAt(m, index);
    if (resolvedAt == null) return null;
    final firstCorrect = _firstCorrectAt(index);
    final _RoundWinner winner;
    if (firstCorrect == null) {
      winner = _RoundWinner.nobody;
    } else if (firstCorrect.playerId == _meId) {
      winner = _RoundWinner.me;
    } else {
      winner = _RoundWinner.opponent;
    }
    final secondsLeft = (_postRoundPause -
            DateTime.now().toUtc().difference(resolvedAt))
        .inMilliseconds /
        1000.0;
    return _RoundOutcome(
      winner: winner,
      correctAnswer: _questions[index].correctAnswer,
      secondsLeft: secondsLeft.clamp(0, _postRoundPause.inSeconds.toDouble()),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final m = _match;

    if (m == null) {
      return const Scaffold(
        body: ParchmentBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (m.status == DuelStatus.cancelled) {
      return const _CancelledScaffold(reason: 'Duell wurde abgebrochen.');
    }

    if (m.status == DuelStatus.waiting) {
      return _WaitingScaffold(
        code: m.code,
        config: m.config,
        isHost: _meId == m.hostId,
        onCancel: _meId == m.hostId ? _cancelLobby : null,
      );
    }

    if (_showConnectSplash) {
      return const _ConnectSplash();
    }

    if (_questions.isEmpty) {
      return const Scaffold(
        body: ParchmentBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final mine = _answersFor(_meId);
    final theirs = _answersFor(_opponentId);

    // External finish (surrender by either side, or status went finished).
    if (m.status == DuelStatus.finished) {
      return _buildSummary(m, mine, theirs);
    }

    final timeRem = _timeRemainingSeconds(m);
    final timeOut = timeRem != null && timeRem <= 0;
    final iAmAlive = _alive(m, mine);
    final oppAlive = _opponentId == null ? false : _alive(m, theirs);
    final bothDead = !iAmAlive && (_opponentId == null || !oppAlive);

    if (timeOut || bothDead) {
      // Auto-finalize on server once, then show summary.
      if (!_finalized && m.status == DuelStatus.playing) {
        _finalized = true;
        ref.read(duelRepositoryProvider)?.finish(m.code);
      }
      return _buildSummary(m, mine, theirs);
    }

    // Opponent disconnected for longer than the grace period -> we win.
    if (_checkOpponentDisconnected(m)) {
      _opponentDisconnected = true;
      if (!_finalized && m.status == DuelStatus.playing) {
        _finalized = true;
        ref.read(duelRepositoryProvider)?.finish(m.code);
      }
      return _buildSummary(m, mine, theirs);
    }

    // Compute the index I should display.
    final raceIdx = m.mode == DuelMode.race ? _raceIndex(m, mine, theirs) : 0;
    final myIdx = m.mode == DuelMode.race ? raceIdx : _parallelIndex(mine);
    final atEnd = myIdx >= _questions.length;
    if (atEnd) {
      if (!_finalized && m.status == DuelStatus.playing) {
        _finalized = true;
        ref.read(duelRepositoryProvider)?.finish(m.code);
      }
      return _buildSummary(m, mine, theirs);
    }

    // Reset per-question UI when index advanced.
    if (myIdx != _renderedIndex) {
      _renderedIndex = myIdx;
      _selectedIndex = -1;
      _typed = '';
      _letterboxKey.currentState?.reset();
      _questionStartedAt = DateTime.now();
    }

    final question = _questions[myIdx];
    final iAnsweredHere = _alreadyAnsweredCurrent(myIdx, mine);
    final oppCorrectHere = m.mode == DuelMode.race
        ? theirs.any((a) => a.questionIndex == myIdx && a.wasCorrect)
        : false;
    final oppWrongHere = m.mode == DuelMode.race &&
        _opponentId != null &&
        theirs.any((a) => a.questionIndex == myIdx && !a.wasCorrect);
    final outcome =
        m.mode == DuelMode.race ? _roundOutcome(m, myIdx) : null;
    final inPause = outcome != null;
    final iAmLocked = !iAmAlive ||
        iAnsweredHere ||
        (m.mode == DuelMode.race && oppCorrectHere) ||
        inPause;

    return Scaffold(
      appBar: AppBar(
        title: Text(m.mode.label),
        actions: [
          IconButton(
            tooltip: 'Aufgeben',
            icon: const Icon(Icons.flag_outlined),
            onPressed: _confirmSurrender,
          ),
        ],
      ),
      body: ParchmentBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                _StatsBar(
                  mode: m.mode,
                  timeRemSeconds: timeRem,
                  myScore: mine.fold<int>(0, (s, a) => s + a.points),
                  myLives: _livesRemaining(m, mine),
                  myProgress: mine.length,
                  oppScore: theirs.fold<int>(0, (s, a) => s + a.points),
                  oppLives: _livesRemaining(m, theirs),
                  oppProgress: theirs.length,
                  myDead: !iAmAlive,
                  oppDead: _opponentId == null ? false : !oppAlive,
                  oppWrongThisRound: oppWrongHere,
                  timerPaused: inPause,
                  hasOpponent: _opponentId != null,
                ),
                const SizedBox(height: 12),
                if (_opponentDisconnectSecondsLeft() != null)
                  _DisconnectWarningBanner(
                    secondsLeft: _opponentDisconnectSecondsLeft()!,
                  ),
                const SizedBox(height: 4),
                if (m.mode == DuelMode.race && !inPause)
                  _RaceStatusBanner(
                    myAlive: iAmAlive,
                    iAnsweredHere: iAnsweredHere,
                    oppCorrectHere: oppCorrectHere,
                    oppWrongHere: oppWrongHere,
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: inPause
                      ? _RoundOutcomeOverlay(outcome: outcome)
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              QuestionPromptCard(
                                key: ValueKey(question.id),
                                question: question,
                                questionNumber: myIdx + 1,
                                totalQuestions: m.mode == DuelMode.race
                                    ? _questions.length
                                    : (mine.length + 1),
                              ),
                              const SizedBox(height: 18),
                              if (m.mode == DuelMode.parallel &&
                                  _parallelInFeedback(mine)) ...[
                                Center(
                                  child: _ParallelFeedbackBanner(
                                    answer: _myLatestParallelAnswer(mine)!,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (m.inputStyle == AnswerInputStyle.letterbox)
                                LetterboxInput(
                                  key: _letterboxKey,
                                  target: question.correctAnswer,
                                  revealed: iAnsweredHere,
                                  wasCorrect:
                                      _lastWasCorrect(question, mine, myIdx),
                                  onChanged: (value) => _typed = value,
                                  onSubmitted: (_) =>
                                      _submit(m, question, myIdx),
                                )
                              else
                                ...List.generate(question.options.length, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AnswerOptionButton(
                                      label: question.options[i],
                                      optionLetter: _letters[i],
                                      onTap: () {
                                        if (iAmLocked) return;
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedIndex = i);
                                      },
                                      isSelected: _selectedIndex == i,
                                      isCorrect: i == question.correctIndex,
                                      isRevealed: iAnsweredHere,
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
      floatingActionButton: inPause
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PrimaryButton(
                  label: _submitLabel(
                    m,
                    iAmLocked,
                    iAnsweredHere,
                    oppCorrectHere,
                    iAmAlive,
                  ),
                  onPressed: iAmLocked || !_canSubmit(m)
                      ? null
                      : () => _submit(m, question, myIdx),
                ),
              ),
            ),
      backgroundColor: palette.parchment,
    );
  }

  String _submitLabel(
    DuelMatch m,
    bool iAmLocked,
    bool iAnsweredHere,
    bool oppCorrectHere,
    bool iAmAlive,
  ) {
    if (!iAmAlive) return 'Du bist ausgeschieden …';
    if (m.mode == DuelMode.race && oppCorrectHere && !iAnsweredHere) {
      return 'Sie war schneller';
    }
    if (m.mode == DuelMode.race && iAnsweredHere) {
      return 'Warte auf nächste Frage …';
    }
    return 'Antwort senden';
  }

  bool _canSubmit(DuelMatch m) {
    if (m.inputStyle == AnswerInputStyle.letterbox) {
      return _typed.trim().isNotEmpty;
    }
    return _selectedIndex >= 0;
  }

  bool _lastWasCorrect(Question q, List<DuelAnswer> mine, int idx) {
    final ans = mine.firstWhere(
      (a) => a.questionIndex == idx,
      orElse: () => DuelAnswer(
        duelCode: '',
        playerId: '',
        questionIndex: idx,
        selectedIndex: -1,
        wasCorrect: false,
        timeTaken: Duration.zero,
        points: 0,
        submittedAt: DateTime.now().toUtc(),
      ),
    );
    return ans.wasCorrect;
  }

  Future<void> _submit(DuelMatch m, Question q, int index) async {
    final me = _meId;
    final repo = ref.read(duelRepositoryProvider);
    if (me == null || repo == null) return;

    // Spiegelt die FAB-Bedingungen: Der Soft-Keyboard-Return der Letterbox
    // ruft _submit direkt auf und darf weder ausgeschiedene Spieler noch
    // gelockte Runden noch Leereingaben durchlassen (F3/F14).
    final mine = _answersFor(me);
    if (_alreadyAnsweredCurrent(index, mine)) return;
    if (!_alive(m, mine)) return;
    if (m.mode == DuelMode.race && _someoneCorrectAt(index)) return;
    if (m.inputStyle == AnswerInputStyle.letterbox &&
        _typed.trim().isEmpty) {
      return;
    }
    if (m.inputStyle != AnswerInputStyle.letterbox && _selectedIndex < 0) {
      return;
    }

    final picked = m.inputStyle == AnswerInputStyle.letterbox
        ? (answersMatch(_typed, q.correctAnswer) ? q.correctIndex : -1)
        : _selectedIndex;
    final wasCorrect = picked == q.correctIndex;
    final dt = DateTime.now().difference(_questionStartedAt);

    // Race mode: if opponent already has a correct answer for this index,
    // I cannot score even if I'm now correct.
    final lockedFromPoints =
        m.mode == DuelMode.race && _someoneCorrectAt(index);
    final base =
        wasCorrect && !lockedFromPoints ? 100 + (q.difficulty - 1) * 25 : 0;
    final bonus = wasCorrect && !lockedFromPoints
        ? ((20000 - dt.inMilliseconds).clamp(0, 20000) / 20000 * 50).round()
        : 0;
    final pts = base + bonus;

    HapticFeedback.mediumImpact();
    await repo.submitAnswer(
      code: widget.code,
      playerId: me,
      questionIndex: index,
      selectedIndex: picked,
      wasCorrect: wasCorrect,
      timeTaken: dt,
      points: pts,
    );
  }

  // ─── Summary screen ───────────────────────────────────────────────────────

  Widget _buildSummary(DuelMatch m, List<DuelAnswer> me, List<DuelAnswer> opp) {
    final palette = context.palette;
    final myScore = me.fold<int>(0, (s, a) => s + a.points);
    final oppScore = opp.fold<int>(0, (s, a) => s + a.points);
    final myCorrect = me.where((a) => a.wasCorrect).length;
    final oppCorrect = opp.where((a) => a.wasCorrect).length;

    // Sieg-Logik: Disconnect-Timeout gewinnt lokal sofort, sonst Score und
    // Korrekte als Tiebreak.
    final int? winSign = _opponentDisconnected
        ? 1
        : oppScore == myScore
            ? (myCorrect == oppCorrect
                ? null
                : (myCorrect > oppCorrect ? 1 : -1))
            : (myScore > oppScore ? 1 : -1);
    final iWin = winSign == 1;
    final tie = winSign == null;
    final rematchCode = m.rematchCode;

    // XP + Duell-Statistiken einmalig verbuchen, sobald das Duell
    // serverseitig finished ist — vorher kann sich der Ausgang durch
    // nachlaufende Antworten noch ändern (F1).
    if (!_resultApplied && m.status == DuelStatus.finished) {
      _resultApplied = true;
      _applyDuelResult(m, me, won: iWin, correctCount: myCorrect);
    }

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
                      : (iWin ? 'Gewonnen.' : 'Knapp daneben.'),
                  textAlign: TextAlign.center,
                  style: AppTypography.serif(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                    letterSpacing: -0.6,
                  ),
                ),
                if (_opponentDisconnected) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Mitspielerin hat die Verbindung verloren.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.inkMuted,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ScorePillar(
                        label: 'Du',
                        score: myScore,
                        correct: myCorrect,
                        answered: me.length,
                        highlight: iWin,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ScorePillar(
                        label: 'Mitspielerin',
                        score: oppScore,
                        correct: oppCorrect,
                        answered: opp.length,
                        highlight: !iWin && !tie,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (rematchCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.gold.withValues(alpha: 0.14),
                      border: Border.all(color: palette.gold),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Revanche bereit',
                          style: AppTypography.serif(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code $rematchCode',
                          style: AppTypography.sans(
                            fontSize: 13,
                            color: palette.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Beitreten',
                          icon: Icons.login_rounded,
                          onPressed: () => _joinRematch(rematchCode),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Zurück zum Menü',
                    onPressed: () => context.go('/'),
                  ),
                ] else ...[
                  PrimaryButton(
                    label: 'Revanche',
                    icon: Icons.refresh_rounded,
                    onPressed: _startRematch,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Zurück zum Menü',
                    onPressed: () => context.go('/'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Verbucht das Duell im Spielerprofil: XP (20 pro richtiger Antwort wie
  /// im Quiz, +50 Siegbonus), totalGamesPlayed, Tages-Streak und die
  /// Duell-Zähler hinter den Achievements `first_duel_won`/`duel_streak`.
  /// Post-Frame, weil wir mitten im build() des Summary stecken.
  void _applyDuelResult(
    DuelMatch m,
    List<DuelAnswer> myAnswers, {
    required bool won,
    required int correctCount,
  }) {
    final records = <AnswerRecord>[
      for (final a in myAnswers)
        if (a.questionIndex < _questions.length)
          AnswerRecord(
            questionId: _questions[a.questionIndex].id,
            selectedIndex: a.selectedIndex,
            wasCorrect: a.wasCorrect,
            timeTaken: a.timeTaken,
            points: a.points,
          ),
    ];
    final session = GameSession(
      id: 'duel-${m.code}',
      mode: GameMode.vsOnline,
      questions: _questions,
      startedAt: m.startedAt ?? DateTime.now(),
      inputStyle: m.inputStyle,
      answers: records,
    );
    final xp = correctCount * 20 + (won ? 50 : 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileNotifierProvider.notifier).applySessionResult(
            session: session,
            xpGained: xp,
            wonDuel: won,
          );
    });
  }

  Future<void> _startRematch() async {
    final repo = ref.read(duelRepositoryProvider);
    final profile = ref.read(profileNotifierProvider).value;
    final m = _match;
    if (repo == null || profile == null || m == null) return;
    try {
      final rematch = await repo.createRematch(original: m, hostId: profile.id);
      if (!mounted) return;
      context.go('/duel/${rematch.code}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Revanche fehlgeschlagen: $e')),
      );
    }
  }

  Future<void> _joinRematch(String code) async {
    final repo = ref.read(duelRepositoryProvider);
    final profile = ref.read(profileNotifierProvider).value;
    if (repo == null || profile == null) return;
    try {
      await repo.joinDuel(code: code, guestId: profile.id);
      if (!mounted) return;
      context.go('/duel/$code');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beitritt zur Revanche fehlgeschlagen: $e')),
      );
    }
  }
}

// ─── Stats bar (top of match screen) ────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.mode,
    required this.timeRemSeconds,
    required this.myScore,
    required this.myLives,
    required this.myProgress,
    required this.oppScore,
    required this.oppLives,
    required this.oppProgress,
    required this.myDead,
    required this.oppDead,
    this.oppWrongThisRound = false,
    this.timerPaused = false,
    this.hasOpponent = false,
  });

  final DuelMode mode;
  final double? timeRemSeconds;
  final int myScore;
  final int? myLives;
  final int myProgress;
  final int oppScore;
  final int? oppLives;
  final int oppProgress;
  final bool myDead;
  final bool oppDead;

  /// Opponent has already submitted a wrong answer on the current race
  /// round. Pill on their side renders a persistent "Falsch" badge until
  /// the round advances.
  final bool oppWrongThisRound;

  /// Shared session timer is currently frozen (between rounds). The
  /// [_TimerStrip] picks this up to show a paused visual instead of
  /// ticking down.
  final bool timerPaused;

  /// Whether there's a guest player at all. While the lobby is still
  /// solo (waiting for someone to join), the lead-highlight is
  /// suppressed — there's nobody to be ahead of.
  final bool hasOpponent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // "Führend" rein nach Score — nur wenn es überhaupt einen Gegner gibt
    // und der Spielstand nicht gleich ist. Bei toten Spielern bleibt die
    // Markierung aus (die "AUS"-Anzeige übernimmt den Status).
    final myLead =
        hasOpponent && !myDead && !oppDead && myScore > oppScore;
    final oppLead =
        hasOpponent && !myDead && !oppDead && oppScore > myScore;
    return Column(
      children: [
        if (timeRemSeconds != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TimerStrip(
              secondsLeft: timeRemSeconds!,
              paused: timerPaused,
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _PlayerPill(
                label: 'DU',
                score: myScore,
                lives: myLives,
                progress: myProgress,
                isMe: true,
                isDead: myDead,
                leading: myLead,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PlayerPill(
                label: 'MITSPIELERIN',
                score: oppScore,
                lives: oppLives,
                progress: oppProgress,
                isMe: false,
                isDead: oppDead,
                wrongThisRound: oppWrongThisRound,
                leading: oppLead,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          mode == DuelMode.race
              ? 'Race · erste richtige Antwort gewinnt'
              : 'Parallel · Summe entscheidet',
          style: AppTypography.eyebrow(palette.gold),
        ),
      ],
    );
  }
}

class _TimerStrip extends StatelessWidget {
  const _TimerStrip({
    required this.secondsLeft,
    this.paused = false,
  });
  final double secondsLeft;

  /// When true, the strip renders a neutral "paused" visual instead of the
  /// low-time alarm or normal countdown. Used during the race post-round
  /// window so the shared timer visibly stops.
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = secondsLeft.clamp(0, 9999);
    final mins = (s ~/ 60).toString();
    final secs = (s.truncate() % 60).toString().padLeft(2, '0');
    final lowTime = !paused && s <= 10;

    final borderColor = paused
        ? palette.gold.withValues(alpha: 0.6)
        : (lowTime ? palette.incorrect : palette.divider);
    final fillColor = paused
        ? palette.gold.withValues(alpha: 0.10)
        : (lowTime
            ? palette.incorrect.withValues(alpha: 0.15)
            : palette.page);
    final iconColor = paused
        ? palette.gold
        : (lowTime ? palette.incorrect : palette.gold);
    final textColor = paused
        ? palette.inkMuted
        : (lowTime ? palette.incorrect : palette.ink);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(
          color: borderColor,
          width: lowTime || paused ? 1.3 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paused ? Icons.pause_circle_outline_rounded : Icons.timer_rounded,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            '$mins:$secs',
            style: AppTypography.serif(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
          if (paused) ...[
            const SizedBox(width: 8),
            Text(
              'PAUSE',
              style: AppTypography.eyebrow(palette.gold),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerPill extends StatelessWidget {
  const _PlayerPill({
    required this.label,
    required this.score,
    required this.lives,
    required this.progress,
    required this.isMe,
    required this.isDead,
    this.wrongThisRound = false,
    this.leading = false,
  });

  final String label;
  final int score;
  final int? lives;
  final int progress;
  final bool isMe;
  final bool isDead;

  /// Render a persistent "FALSCH" badge plus a red border to flag that
  /// this player has already burned their answer on the current race round.
  /// Pulses briefly on first appearance via flutter_animate's repeat.
  final bool wrongThisRound;

  /// This player currently has the higher score. Adds a gold accent
  /// (border + soft tint + "FÜHRT"-Badge) so the leader is immediately
  /// readable. Overridden by [wrongThisRound] / [isDead] which take
  /// visual priority.
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Visuelle Priorität: wrongThisRound (rot) > isDead (gedimmt) >
    // leading (gold) > isMe (burgundy) > neutral.
    final borderColor = wrongThisRound
        ? palette.incorrect
        : (leading && !isDead
            ? palette.gold
            : (isMe ? palette.burgundy : palette.divider));
    final borderWidth = wrongThisRound
        ? 1.6
        : (leading && !isDead ? 1.6 : (isMe ? 1.4 : 1));
    final fillColor = wrongThisRound
        ? palette.incorrect.withValues(alpha: 0.07)
        : (isDead
            ? palette.parchment.withValues(alpha: 0.5)
            : (leading
                ? palette.gold.withValues(alpha: 0.08)
                : palette.page));
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: borderWidth.toDouble()),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTypography.eyebrow(palette.inkMuted)),
              const Spacer(),
              if (isDead)
                Text(
                  'AUS',
                  style: AppTypography.eyebrow(palette.incorrect),
                )
              else if (wrongThisRound)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.incorrect,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✗ FALSCH',
                    style: AppTypography.eyebrow(palette.page)
                        .copyWith(color: palette.page, letterSpacing: 1.4),
                  ),
                )
              else if (leading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '★ FÜHRT',
                    style: AppTypography.eyebrow(palette.page)
                        .copyWith(color: palette.page, letterSpacing: 1.4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$score',
                style: AppTypography.serif(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: palette.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'P',
                style: AppTypography.serif(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: palette.inkMuted,
                ),
              ),
              const Spacer(),
              if (lives != null)
                _LivesIndicator(lives: lives!)
              else
                Icon(
                  Icons.all_inclusive_rounded,
                  size: 16,
                  color: palette.gold,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$progress Frage(n)',
            style: AppTypography.sans(fontSize: 11, color: palette.inkMuted),
          ),
        ],
      ),
    );

    if (!wrongThisRound) return pill;
    // Wrong-this-round: quick attention-grabbing pulse on first appearance,
    // then settle into a steady red-bordered state.
    return pill
        .animate(key: ValueKey('${label}_wrong'))
        .shake(hz: 4, duration: 360.ms, offset: const Offset(1.4, 0))
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 220.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _LivesIndicator extends StatelessWidget {
  const _LivesIndicator({required this.lives});
  final int lives;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (lives > 5) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 14, color: palette.burgundy),
          const SizedBox(width: 3),
          Text(
            '$lives',
            style: AppTypography.serif(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.burgundy,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lives; i++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child:
                Icon(Icons.favorite_rounded, size: 13, color: palette.burgundy),
          ),
      ],
    );
  }
}

class _DisconnectWarningBanner extends StatelessWidget {
  const _DisconnectWarningBanner({required this.secondsLeft});
  final double secondsLeft;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = secondsLeft.ceil().clamp(0, 99);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.incorrect.withValues(alpha: 0.14),
        border: Border.all(color: palette.incorrect.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_wifi_bad_rounded,
            size: 16,
            color: palette.incorrect,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mitspielerin offline',
              style: TextStyle(
                color: palette.incorrect,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.timer_rounded, size: 14, color: palette.incorrect),
          const SizedBox(width: 4),
          Text(
            'Match endet in ${s}s',
            style: AppTypography.serif(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.incorrect,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Local "Richtig/Falsch"-Einblendung after a parallel-mode answer.
/// Lifetime is driven by [_DuelMatchScreenState._parallelFeedbackDuration]
/// — the banner just renders whatever it gets and lets the parent decide
/// when to remove it.
class _ParallelFeedbackBanner extends StatelessWidget {
  const _ParallelFeedbackBanner({required this.answer});
  final DuelAnswer answer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ok = answer.wasCorrect;
    final color = ok ? palette.correct : palette.incorrect;
    final icon = ok ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final text = ok ? 'Richtig — +${answer.points} P' : 'Leider falsch';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTypography.serif(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey('feedback_${answer.questionIndex}')).fadeIn(
          duration: 160.ms,
        ).scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 240.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _RaceStatusBanner extends StatelessWidget {
  const _RaceStatusBanner({
    required this.myAlive,
    required this.iAnsweredHere,
    required this.oppCorrectHere,
    this.oppWrongHere = false,
  });

  final bool myAlive;
  final bool iAnsweredHere;
  final bool oppCorrectHere;

  /// Opponent has submitted a wrong answer on the current round and is now
  /// locked out — frees me to answer at my own pace for points.
  final bool oppWrongHere;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    String? text;
    Color? color;
    if (!myAlive) {
      text = 'Du bist ausgeschieden — Mitspielerin kann weitermachen.';
      color = palette.incorrect;
    } else if (oppCorrectHere && !iAnsweredHere) {
      text = 'Sie war schneller. Diese Frage zählt nicht.';
      color = palette.incorrect;
    } else if (iAnsweredHere && !oppCorrectHere) {
      text = 'Du hast geantwortet — warte auf Mitspielerin.';
      color = palette.gold;
    } else if (oppWrongHere && !iAnsweredHere) {
      text = 'Mitspielerin hat falsch geantwortet — freie Bahn für dich.';
      color = palette.correct;
    }
    if (text == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color!.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Waiting (lobby) ────────────────────────────────────────────────────────

class _WaitingScaffold extends StatefulWidget {
  const _WaitingScaffold({
    required this.code,
    required this.config,
    required this.isHost,
    required this.onCancel,
  });
  final String code;
  final DuelConfig config;
  final bool isHost;
  final VoidCallback? onCancel;

  @override
  State<_WaitingScaffold> createState() => _WaitingScaffoldState();
}

class _WaitingScaffoldState extends State<_WaitingScaffold> {
  static const _timeoutSeconds = 5 * 60;
  Timer? _ticker;
  late DateTime _openedAt;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_openedAt).inSeconds;
      if (elapsed >= _timeoutSeconds) {
        _ticker?.cancel();
        widget.onCancel?.call();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _remaining() {
    final left =
        _timeoutSeconds - DateTime.now().difference(_openedAt).inSeconds;
    final m = (left ~/ 60).clamp(0, 99);
    final s = (left % 60).clamp(0, 59).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        actions: [
          if (widget.isHost && widget.onCancel != null)
            IconButton(
              tooltip: 'Lobby schliessen',
              icon: const Icon(Icons.close_rounded),
              onPressed: widget.onCancel,
            ),
        ],
      ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(
                    color: palette.page,
                    border: Border.all(color: palette.divider),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.code,
                    style: AppTypography.serif(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: palette.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // QR-Code mit demselben 6-stelligen Lobby-Code als Payload.
                // Der Join-Scanner extrahiert den Code wieder direkt.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.page,
                    border: Border.all(color: palette.divider),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: widget.code,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: palette.page,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: palette.ink,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: palette.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ConfigChip(label: widget.config.mode.label),
                    _ConfigChip(label: 'Zeit ${widget.config.timeLabel}'),
                    _ConfigChip(label: 'Leben ${widget.config.livesLabel}'),
                    _ConfigChip(label: widget.config.inputStyle.shortLabel),
                    _ConfigChip(label: widget.config.difficultyBand.label),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Warte auf Mitspielerin …',
                  style: TextStyle(color: palette.inkMuted, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lobby schliesst sich in ${_remaining()}',
                  style: TextStyle(color: palette.inkMuted, fontSize: 12),
                ),
                const SizedBox(height: 22),
                IconButton.filled(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.code));
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

// ─── Connect-Splash & Cancelled-Scaffold ────────────────────────────────────

class _ConnectSplash extends StatelessWidget {
  const _ConnectSplash();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: ParchmentBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WaxSeal(symbol: '⚔', size: 76).animate().scale(
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                  ),
              const SizedBox(height: 22),
              Text(
                'Mitspielerin verbunden',
                style: AppTypography.serif(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Es geht los …',
                style: TextStyle(color: palette.inkMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelledScaffold extends StatelessWidget {
  const _CancelledScaffold({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: ParchmentBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_outlined, size: 48, color: palette.inkMuted),
                const SizedBox(height: 18),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: AppTypography.serif(
                    fontSize: 18,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 24),
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

class _ConfigChip extends StatelessWidget {
  const _ConfigChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.gold.withValues(alpha: 0.14),
        border: Border.all(color: palette.gold.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.sans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
      ),
    );
  }
}

// ─── Summary widgets ───────────────────────────────────────────────────────

class _ScorePillar extends StatelessWidget {
  const _ScorePillar({
    required this.label,
    required this.score,
    required this.correct,
    required this.answered,
    required this.highlight,
  });

  final String label;
  final int score;
  final int correct;
  final int answered;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
            '$score',
            style: AppTypography.serif(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: highlight ? palette.gold : palette.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$correct/$answered richtig',
            style: AppTypography.sans(fontSize: 12, color: palette.inkMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Race round-end overlay ────────────────────────────────────────────────

enum _RoundWinner { me, opponent, nobody }

class _RoundOutcome {
  const _RoundOutcome({
    required this.winner,
    required this.correctAnswer,
    required this.secondsLeft,
  });

  final _RoundWinner winner;
  final String correctAnswer;

  /// Seconds remaining in the 3-second post-round window, clamped to >= 0.
  final double secondsLeft;
}

class _RoundOutcomeOverlay extends StatelessWidget {
  const _RoundOutcomeOverlay({required this.outcome});
  final _RoundOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final String headline;
    final String symbol;
    final Color accent;
    switch (outcome.winner) {
      case _RoundWinner.me:
        headline = 'Du warst schneller!';
        symbol = '✪';
        accent = palette.gold;
      case _RoundWinner.opponent:
        headline = 'Mitspielerin war schneller';
        symbol = '◎';
        accent = palette.burgundy;
      case _RoundWinner.nobody:
        headline = 'Keine richtige Antwort.';
        symbol = '◯';
        accent = palette.inkMuted;
    }

    final ringProgress =
        1 - (outcome.secondsLeft / _DuelMatchScreenState._postRoundPause.inSeconds);
    final secondsDisplay = outcome.secondsLeft.ceil().clamp(0, 9);

    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: palette.page,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WaxSeal(symbol: symbol, size: 92, color: accent)
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 460.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 18),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: AppTypography.serif(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'KORREKTE ANTWORT',
                style: AppTypography.eyebrow(palette.inkMuted),
              ),
              const SizedBox(height: 4),
              Text(
                outcome.correctAnswer,
                textAlign: TextAlign.center,
                style: AppTypography.serif(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: ringProgress.clamp(0, 1).toDouble(),
                        strokeWidth: 4,
                        backgroundColor: palette.divider,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                    Text(
                      '$secondsDisplay',
                      style: AppTypography.serif(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nächste Frage gleich …',
                style: TextStyle(
                  color: palette.inkMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
