import 'dart:math' as math;

import '../../features/letterbox/answer_normalization.dart';
import '../models/question.dart';
import '../seed/questions_seed.dart';

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
  List<Question> randomBatch({
    required int count,
    Set<QuestionCategory> categories = const {},
    int minDifficulty = 1,
    int maxDifficulty = 5,
    int? seed,
    bool letterboxFriendlyOnly = false,
  }) {
    final candidates = filter(
      categories: categories,
      minDifficulty: minDifficulty,
      maxDifficulty: maxDifficulty,
      letterboxFriendlyOnly: letterboxFriendlyOnly,
    );
    final rng = math.Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    candidates.shuffle(rng);

    final picked = <Question>[];
    final seenTopics = <String>{};
    for (final q in candidates) {
      if (picked.length >= count) break;
      if (q.topicKey != null && seenTopics.contains(q.topicKey)) continue;
      picked.add(q);
      if (q.topicKey != null) seenTopics.add(q.topicKey!);
    }

    return picked.map((q) => _shuffleOptions(q, rng)).toList();
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
