import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../data/models/answer_input_style.dart';
import '../../data/models/game_session.dart';
import '../../data/models/player_profile.dart';
import '../../data/models/question.dart';
import '../letterbox/answer_normalization.dart';
import '../letterbox/letterbox_joker.dart';

/// Configuration for starting a new session.
class GameConfig {
  const GameConfig({
    required this.mode,
    this.questionCount = 10,
    this.categories = const {},
    this.difficultyMin = 1,
    this.difficultyMax = 5,
    this.perQuestionTimeLimit = const Duration(seconds: 20),
    this.sessionTimeLimit,
    this.lifeLimit,
    this.inputStyle = AnswerInputStyle.multipleChoice,
    this.sessionLabel,
  });

  final GameMode mode;
  final int questionCount;
  final Set<QuestionCategory> categories;
  final int difficultyMin;
  final int difficultyMax;
  final Duration perQuestionTimeLimit;
  final Duration? sessionTimeLimit;
  final int? lifeLimit;
  final AnswerInputStyle inputStyle;
  final String? sessionLabel;

  static const classicDefault = GameConfig(
    mode: GameMode.classic,
    perQuestionTimeLimit: Duration.zero,
  );
  static const quizRushOneMinute = GameConfig(
    mode: GameMode.quizRush,
    questionCount: 200,
    perQuestionTimeLimit: Duration.zero,
    sessionTimeLimit: Duration(minutes: 1),
    sessionLabel: 'Best of 1 Minute',
  );
  static const quizRushThreeMinutes = GameConfig(
    mode: GameMode.quizRush,
    questionCount: 200,
    perQuestionTimeLimit: Duration.zero,
    sessionTimeLimit: Duration(minutes: 3),
    sessionLabel: 'Best of 3 Minuten',
  );
  static const quizRushFiveMinutes = GameConfig(
    mode: GameMode.quizRush,
    questionCount: 200,
    perQuestionTimeLimit: Duration.zero,
    sessionTimeLimit: Duration(minutes: 5),
    sessionLabel: 'Best of 5 Minuten',
  );
  static const quizRushEndless = GameConfig(
    mode: GameMode.quizRush,
    questionCount: 200,
    perQuestionTimeLimit: Duration.zero,
    lifeLimit: 3,
    sessionLabel: 'Endless',
  );
  static const suddenDeathDefault = GameConfig(
    mode: GameMode.suddenDeath,
    questionCount: 50,
  );
  static const dailyDefault = GameConfig(
    mode: GameMode.daily,
    questionCount: 5,
  );
  static const practiceDefault = GameConfig(
    mode: GameMode.practice,
    questionCount: 10,
    perQuestionTimeLimit: Duration(minutes: 5),
  );

  /// Same length as classic, but the player types the answer into boxes
  /// instead of picking from four options. Classic sessions are untimed.
  static const letterboxDefault = GameConfig(
    mode: GameMode.classic,
    questionCount: 10,
    inputStyle: AnswerInputStyle.letterbox,
    perQuestionTimeLimit: Duration.zero,
  );

  GameConfig copyWith({
    GameMode? mode,
    int? questionCount,
    Set<QuestionCategory>? categories,
    int? difficultyMin,
    int? difficultyMax,
    Duration? perQuestionTimeLimit,
    Duration? sessionTimeLimit,
    int? lifeLimit,
    AnswerInputStyle? inputStyle,
    String? sessionLabel,
  }) =>
      GameConfig(
        mode: mode ?? this.mode,
        questionCount: questionCount ?? this.questionCount,
        categories: categories ?? this.categories,
        difficultyMin: difficultyMin ?? this.difficultyMin,
        difficultyMax: difficultyMax ?? this.difficultyMax,
        perQuestionTimeLimit: perQuestionTimeLimit ?? this.perQuestionTimeLimit,
        sessionTimeLimit: sessionTimeLimit ?? this.sessionTimeLimit,
        lifeLimit: lifeLimit ?? this.lifeLimit,
        inputStyle: inputStyle ?? this.inputStyle,
        sessionLabel: sessionLabel ?? this.sessionLabel,
      );
}

/// Holds an ongoing [GameSession] and per-question UI state.
class GameSessionState {
  const GameSessionState({
    required this.session,
    required this.config,
    required this.selectedIndex,
    required this.revealed,
    required this.eliminatedIndices,
    required this.revealedLetterIndices,
    required this.fiftyFiftyUses,
    required this.jokerAvailability,
    required this.questionStartedAt,
    required this.unlockedAchievements,
  });

  final GameSession session;
  final GameConfig config;

  /// -1 if not yet picked.
  final int selectedIndex;
  final bool revealed;
  final Set<int> eliminatedIndices;
  final Set<int> revealedLetterIndices;
  final int fiftyFiftyUses;
  final JokerAvailability jokerAvailability;
  final DateTime questionStartedAt;
  final List<String> unlockedAchievements;

  GameSessionState copyWith({
    int? selectedIndex,
    bool? revealed,
    Set<int>? eliminatedIndices,
    Set<int>? revealedLetterIndices,
    int? fiftyFiftyUses,
    DateTime? questionStartedAt,
    List<String>? unlockedAchievements,
  }) =>
      GameSessionState(
        session: session,
        config: config,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        revealed: revealed ?? this.revealed,
        eliminatedIndices: eliminatedIndices ?? this.eliminatedIndices,
        revealedLetterIndices:
            revealedLetterIndices ?? this.revealedLetterIndices,
        fiftyFiftyUses: fiftyFiftyUses ?? this.fiftyFiftyUses,
        jokerAvailability: jokerAvailability,
        questionStartedAt: questionStartedAt ?? this.questionStartedAt,
        unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      );
}

/// Family provider — one controller per session.
final gameSessionProvider = StateNotifierProvider.autoDispose
    .family<GameSessionController, GameSessionState, GameConfig>(
  (ref, config) => GameSessionController(ref, config),
);

class GameSessionController extends StateNotifier<GameSessionState> {
  GameSessionController(Ref ref, GameConfig config)
      : super(_initial(ref, config));

  static GameSessionState _initial(Ref ref, GameConfig config) {
    final repo = ref.read(questionRepositoryProvider);
    final letterboxOnly = config.inputStyle == AnswerInputStyle.letterbox;
    final questions = config.mode == GameMode.daily
        ? repo.dailyBatch(DateTime.now(), count: config.questionCount)
        : repo.randomBatch(
            count: config.questionCount,
            categories: config.categories,
            minDifficulty: config.difficultyMin,
            maxDifficulty: config.difficultyMax,
            letterboxFriendlyOnly: letterboxOnly,
          );

    final session = GameSession(
      id: const Uuid().v4(),
      mode: config.mode,
      questions: questions,
      startedAt: DateTime.now(),
      categories: config.categories,
      difficultyMin: config.difficultyMin,
      difficultyMax: config.difficultyMax,
      inputStyle: config.inputStyle,
    );

    return GameSessionState(
      session: session,
      config: config,
      selectedIndex: -1,
      revealed: false,
      eliminatedIndices: const {},
      revealedLetterIndices: const {},
      fiftyFiftyUses: 0,
      jokerAvailability:
          ref.read(profileNotifierProvider).value?.jokerAvailability ??
              JokerAvailability.always,
      questionStartedAt: DateTime.now(),
      unlockedAchievements: const [],
    );
  }

  // ─── Power-ups ───
  bool get canUseFiftyFifty {
    final q = state.session.currentQuestion;
    if (q == null || state.revealed || _fiftyFiftyUsedOnCurrentQuestion) {
      return false;
    }
    final limit = state.jokerAvailability.sessionLimit;
    if (limit != null && state.fiftyFiftyUses >= limit) return false;
    if (state.config.inputStyle == AnswerInputStyle.letterbox) {
      return letterboxFiftyFiftyRevealCount(q.correctAnswer) > 0;
    }
    return q.options.length > 2;
  }

  int? get fiftyFiftyRemaining {
    final limit = state.jokerAvailability.sessionLimit;
    if (limit == null) return null;
    return math.max(0, limit - state.fiftyFiftyUses);
  }

  bool get _fiftyFiftyUsedOnCurrentQuestion =>
      state.eliminatedIndices.isNotEmpty ||
      state.revealedLetterIndices.isNotEmpty;

  void useFiftyFifty() {
    final q = state.session.currentQuestion;
    if (q == null || !canUseFiftyFifty) return;

    if (state.config.inputStyle == AnswerInputStyle.letterbox) {
      final revealed = pickLetterboxFiftyFiftyIndices(q.correctAnswer);
      if (revealed.isEmpty) return;
      state = state.copyWith(
        revealedLetterIndices: revealed,
        fiftyFiftyUses: state.fiftyFiftyUses + 1,
      );
      HapticFeedback.lightImpact();
      return;
    }

    final wrong = <int>[
      for (var i = 0; i < q.options.length; i++)
        if (i != q.correctIndex) i,
    ]..shuffle();
    state = state.copyWith(
      eliminatedIndices: {wrong[0], wrong[1]},
      fiftyFiftyUses: state.fiftyFiftyUses + 1,
    );
    HapticFeedback.lightImpact();
  }

  // ─── Answering ───
  void selectOption(int index) {
    if (state.revealed) return;
    if (state.eliminatedIndices.contains(index)) return;
    state = state.copyWith(selectedIndex: index);
    HapticFeedback.selectionClick();
  }

  /// Submits a typed answer (letterbox mode). The match is case- and
  /// umlaut-tolerant. Internally maps to a multiple-choice [submit] using
  /// the question's correctIndex when right, or -1 when wrong.
  AnswerRecord submitTypedAnswer(String typed) {
    final q = state.session.currentQuestion;
    if (q == null) throw StateError('No active question');
    final correct = answersMatch(typed, q.correctAnswer);
    return submit(overrideIndex: correct ? q.correctIndex : -1);
  }

  /// Confirms the current selection (or pass -1 for time-out / skip), reveals
  /// feedback, and appends an [AnswerRecord] to the session. Returns the
  /// resulting record for animation/branch logic.
  AnswerRecord submit({int? overrideIndex}) {
    final q = state.session.currentQuestion;
    if (q == null) {
      throw StateError('No active question');
    }
    final picked = overrideIndex ?? state.selectedIndex;
    final wasCorrect = picked == q.correctIndex;
    final timeTaken = DateTime.now().difference(state.questionStartedAt);
    final points = _scoreFor(q, wasCorrect, timeTaken);
    final usedJokerHere = _fiftyFiftyUsedOnCurrentQuestion
        ? PowerUpKind.fiftyFifty
        : null;

    final record = AnswerRecord(
      questionId: q.id,
      selectedIndex: picked,
      wasCorrect: wasCorrect,
      timeTaken: timeTaken,
      points: points,
      usedPowerUp: usedJokerHere,
    );
    state.session.answers.add(record);
    state = state.copyWith(revealed: true, selectedIndex: picked);

    if (wasCorrect) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    return record;
  }

  /// Move on to the next question, or finish the session.
  void next() {
    if (rushOutOfLives) {
      finishNow();
      return;
    }
    if (state.session.isFinished) return;
    state.session.currentIndex++;
    state = state.copyWith(
      selectedIndex: -1,
      revealed: false,
      eliminatedIndices: const {},
      revealedLetterIndices: const {},
      questionStartedAt: DateTime.now(),
    );
  }

  /// Sudden death helper — true if the session should end early.
  bool get suddenDeathFailed =>
      state.session.mode == GameMode.suddenDeath &&
      state.revealed &&
      !(state.session.answers.lastOrNull?.wasCorrect ?? true);

  bool get rushOutOfLives {
    final limit = state.config.lifeLimit;
    if (state.session.mode != GameMode.quizRush || limit == null) {
      return false;
    }
    return state.session.answers.where((a) => !a.wasCorrect).length >= limit;
  }

  int? get livesRemaining {
    final limit = state.config.lifeLimit;
    if (limit == null) return null;
    final mistakes = state.session.answers.where((a) => !a.wasCorrect).length;
    return (limit - mistakes).clamp(0, limit).toInt();
  }

  void finishNow() {
    state.session.currentIndex = state.session.questions.length;
    state = state.copyWith();
  }

  int _scoreFor(Question q, bool wasCorrect, Duration t) {
    if (!wasCorrect) return 0;
    final base = 100 + (q.difficulty - 1) * 25;
    final limitMs = state.config.perQuestionTimeLimit.inMilliseconds;
    if (limitMs <= 0) return base;
    final speedBonus =
        ((limitMs - t.inMilliseconds).clamp(0, limitMs) / limitMs * 50).round();
    return base + speedBonus;
  }

  /// Compute XP for the whole session — call once on finish.
  int xpForSession() {
    final correct = state.session.correctCount;
    final total = state.session.questions.length;
    final bonus = correct == total ? 50 : 0;
    return correct * 20 + bonus;
  }
}

extension _ListLastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
