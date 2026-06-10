import 'package:flutter_test/flutter_test.dart';
import 'package:philosophie_quiz/data/repositories/question_repository.dart';
import 'package:philosophie_quiz/data/seed/questions_seed.dart';

void main() {
  group('QuestionRepository seeded determinism (B2)', () {
    test('same seed + same pool → identical batch', () {
      final a = QuestionRepository(pool: kQuestions)
          .randomBatch(count: 5, seed: 42);
      final b = QuestionRepository(pool: kQuestions)
          .randomBatch(count: 5, seed: 42);
      expect(
        a.map((q) => q.id).toList(),
        b.map((q) => q.id).toList(),
      );
    });

    test('seeded batch is independent of pool order', () {
      // Duell/Daily: Geräte können denselben Content in unterschiedlicher
      // Reihenfolge halten (Cache vs. Remote vs. Bundle). Der Seed-Lauf
      // muss trotzdem auf beiden dieselben Fragen in derselben Reihenfolge
      // liefern — inklusive identisch gemischter Antwort-Optionen.
      final forward = QuestionRepository(pool: kQuestions.toList())
          .randomBatch(count: 10, seed: 20260610);
      final reversed =
          QuestionRepository(pool: kQuestions.reversed.toList())
              .randomBatch(count: 10, seed: 20260610);

      expect(
        forward.map((q) => q.id).toList(),
        reversed.map((q) => q.id).toList(),
      );
      for (var i = 0; i < forward.length; i++) {
        expect(forward[i].options, reversed[i].options);
        expect(forward[i].correctIndex, reversed[i].correctIndex);
      }
    });

    test('unseeded batches still draw from the full pool', () {
      final batch = QuestionRepository(pool: kQuestions).randomBatch(count: 5);
      expect(batch.length, 5);
      expect(batch.map((q) => q.id).toSet().length, 5);
    });
  });
}
