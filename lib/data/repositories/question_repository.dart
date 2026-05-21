import 'dart:math' as math;

import '../../features/letterbox/answer_normalization.dart';
import '../models/question.dart';
import '../seed/questions_seed.dart';
import 'question_history_repository.dart';

/// Provides filtered & shuffled question batches for sessions.
class QuestionRepository {
  QuestionRepository({List<Question>? pool}) : _pool = pool ?? kQuestions;

  final List<Question> _pool;

  /// All questions matching the filter, regardless of count.
  List<Question> filter({
    Set<QuestionCategory> categories = const {},
    int? minDifficulty,
    int? maxDifficulty,
    bool letterboxFriendlyOnly = false,
  }) {
    return _pool.where((q) {
      if (categories.isNotEmpty && !categories.contains(q.category)) {
        return false;
      }
      if (minDifficulty != null && q.difficulty < minDifficulty) return false;
      if (maxDifficulty != null && q.difficulty > maxDifficulty) return false;
      if (letterboxFriendlyOnly && !isLetterboxFriendly(q.correctAnswer)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Random batch with shuffled options.
  ///
  /// Two questions with the same non-null [Question.topicKey] are considered
  /// spoilers of each other (e.g., "name the philosopher of this quote" and
  /// "complete this quote" on the same quote). At most one question per
  /// topicKey will be included in a single batch.
  ///
  /// When [history] is provided **and** [seed] is null, the sampler weights
  /// candidates so that questions the player recently got right surface
  /// less often. Seeded calls (Daily, Duel) keep pure shuffle so both
  /// players see the same set.
  List<Question> randomBatch({
    required int count,
    Set<QuestionCategory> categories = const {},
    int minDifficulty = 1,
    int maxDifficulty = 5,
    int? seed,
    bool letterboxFriendlyOnly = false,
    Map<String, QuestionStat>? history,
  }) {
    final candidates = filter(
      categories: categories,
      minDifficulty: minDifficulty,
      maxDifficulty: maxDifficulty,
      letterboxFriendlyOnly: letterboxFriendlyOnly,
    );
    final rng = math.Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final useWeighting = seed == null && history != null && history.isNotEmpty;

    final picked = <Question>[];
    final seenTopics = <String>{};

    if (useWeighting) {
      // Weighted sampling without replacement: each pick recomputes the
      // pool weights and draws by cumulative-weight bucket. O(N·count) —
      // fine for ~600 questions × ≤20 picks.
      final pool = List<Question>.from(candidates);
      while (picked.length < count && pool.isNotEmpty) {
        final weights = [
          for (final q in pool) _historyWeight(q.id, history),
        ];
        final total = weights.fold<double>(0, (s, w) => s + w);
        if (total <= 0) break;
        var target = rng.nextDouble() * total;
        var idx = pool.length - 1;
        for (var i = 0; i < pool.length; i++) {
          target -= weights[i];
          if (target <= 0) {
            idx = i;
            break;
          }
        }
        final q = pool.removeAt(idx);
        if (q.topicKey != null && seenTopics.contains(q.topicKey)) continue;
        picked.add(q);
        if (q.topicKey != null) seenTopics.add(q.topicKey!);
      }
    } else {
      candidates.shuffle(rng);
      for (final q in candidates) {
        if (picked.length >= count) break;
        if (q.topicKey != null && seenTopics.contains(q.topicKey)) continue;
        picked.add(q);
        if (q.topicKey != null) seenTopics.add(q.topicKey!);
      }
    }

    return picked.map((q) => _shuffleOptions(q, rng)).toList();
  }

  /// Weighting curve for [randomBatch] history mode. Returns a relative
  /// probability multiplier — never zero, so every question can still be
  /// drawn eventually.
  ///
  /// Tuning:
  /// - Never seen → 1.0 (default).
  /// - Last-correct < 7 days → 0.15 (strong cooldown).
  /// - Last-correct 7–30 days → 0.5 (mild cooldown).
  /// - Last-correct > 30 days → 1.0 (cooldown expired).
  /// - Player struggles with this question (wrong > correct, at least one
  ///   correct so we know it's not just a brand-new wrong) → ×1.5 to
  ///   bias toward review.
  static double _historyWeight(String id, Map<String, QuestionStat> history) {
    final stat = history[id];
    if (stat == null) return 1.0;
    final now = DateTime.now().toUtc();
    var w = 1.0;
    final lastCorrect = stat.lastCorrectAt;
    if (lastCorrect != null) {
      final daysSince = now.difference(lastCorrect).inDays;
      if (daysSince < 7) {
        w = 0.15;
      } else if (daysSince < 30) {
        w = 0.5;
      }
    }
    if (stat.wrongCount > stat.correctCount && stat.correctCount > 0) {
      w *= 1.5;
    }
    return w;
  }

  /// Deterministic batch for the daily challenge — same questions for everyone
  /// playing on the same calendar day.
  List<Question> dailyBatch(DateTime date, {int count = 5}) {
    final seed = _dateSeed(date);
    return randomBatch(count: count, seed: seed);
  }

  static int _dateSeed(DateTime date) =>
      date.toUtc().year * 10000 + date.toUtc().month * 100 + date.toUtc().day;

  Question _shuffleOptions(Question q, math.Random rng) {
    final indices = List<int>.generate(q.options.length, (i) => i)..shuffle(rng);
    final newOptions = [for (final i in indices) q.options[i]];
    final newCorrect = indices.indexOf(q.correctIndex);
    return Question(
      id: q.id,
      category: q.category,
      prompt: q.prompt,
      options: newOptions,
      correctIndex: newCorrect,
      difficulty: q.difficulty,
      attribution: q.attribution,
      explanation: q.explanation,
      philosopherId: q.philosopherId,
    );
  }
}
