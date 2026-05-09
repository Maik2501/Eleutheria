import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../data/models/game_session.dart';
import '../../data/models/question.dart';
import '../letterbox/answer_normalization.dart';

/// How the player answers each question.
enum AnswerInputStyle {
  /// Tap one of four options.
  multipleChoice,

  /// Type the answer into letter boxes whose count matches the answer length.
  letterbox,
}

/// Configuration for starting a new session.
class GameConfig {
  const GameConfig({
    required this.mode,
    this.questionCount = 10,
    this.categories = const {},
    this.difficultyMin = 1,
    this.difficultyMax = 5,
    this.perQuestionTimeLimit = const Duration(seconds: 20),
    this.inputStyle = AnswerInputStyle.multipleChoice,
  });

  final GameMode mode;
  final int questionCount;
  final Set<QuestionCategory> categories;
  final int difficultyMin;
  final int difficultyMax;
  final Duration perQuestionTimeLimit;
  final AnswerInputStyle inputStyle;

  static const classicDefault = GameConfig(mode: GameMode.classic);
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
  /// instead of picking from four options. Time limit is generous because
  /// typing is slower than tapping.
  static const letterboxDefault = GameConfig(
    mode: GameMode.classic,
    questionCount: 10,
    inputStyle: AnswerInputStyle.letterbox,
    perQuestionTimeLimit: Duration(seconds: 45),
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
    required this.questionStartedAt,
    required this.unlockedAchievements,
  });

  final GameSession session;
  final GameConfig config;

  /// -1 if not yet picked.
  final int selectedIndex;
  final bool revealed;
  final Set<int> eliminatedIndices;
  final DateTime questionStartedAt;
  final List<String> unlockedAchievements;

  GameSessionState copyWith({
    int? selectedIndex,
    bool? revealed,
    Set<int>? eliminatedIndices,
    DateTime? questionStartedAt,
    List<String>? unlockedAchievements,
  }) =>
      GameSessionState(
        session: session,
        config: config,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        revealed: revealed ?? this.revealed,
        eliminatedIndices: eliminatedIndices ?? this.eliminatedIndices,
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
    );

    return GameSessionState(
      session: session,
      config: config,
      selectedIndex: -1,
      revealed: false,
      eliminatedIndices: const {},
      questionStartedAt: DateTime.now(),
      unlockedAchievements: const [],
    );
  }

  // ─── Power-ups ───
  void useFiftyFifty() {
    final q = state.session.currentQuestion;
    if (q == null || state.revealed || state.eliminatedIndices.isNotEmpty) return;
    final wrong = <int>[
      for (var i = 0; i < q.options.length; i++)
        if (i != q.correctIndex) i,
    ]..shuffle();
    state = state.copyWith(eliminatedIndices: {wrong[0], wrong[1]});
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

    final record = AnswerRecord(
      questionId: q.id,
      selectedIndex: picked,
      wasCorrect: wasCorrect,
      timeTaken: timeTaken,
      points: points,
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
    if (state.session.isFinished) return;
    state.session.currentIndex++;
    state = state.copyWith(
      selectedIndex: -1,
      revealed: false,
      eliminatedIndices: const {},
      questionStartedAt: DateTime.now(),
    );
  }

  /// Sudden death helper — true if the session should end early.
  bool get suddenDeathFailed =>
      state.session.mode == GameMode.suddenDeath &&
      state.revealed &&
      !(state.session.answers.lastOrNull?.wasCorrect ?? true);

  int _scoreFor(Question q, bool wasCorrect, Duration t) {
    if (!wasCorrect) return 0;
    final base = 100 + (q.difficulty - 1) * 25;
    final speedBonus =
        ((state.config.perQuestionTimeLimit.inMilliseconds - t.inMilliseconds)
                    .clamp(0, state.config.perQuestionTimeLimit.inMilliseconds) /
                state.config.perQuestionTimeLimit.inMilliseconds *
                50)
            .round();
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
