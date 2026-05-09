import 'dart:async';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/question.dart';
import '../../data/repositories/question_repository.dart';

/// A duel match — two players answering the same five questions.
///
/// Backed by Supabase tables:
///
/// ```sql
/// create table duels (
///   code text primary key,                -- 6-char join code
///   host_id uuid not null,
///   guest_id uuid,
///   question_seed bigint not null,
///   question_count int not null default 5,
///   status text not null default 'waiting',  -- waiting | playing | finished
///   created_at timestamptz default now()
/// );
///
/// create table duel_answers (
///   duel_code text references duels(code) on delete cascade,
///   player_id uuid not null,
///   question_index int not null,
///   selected_index int not null,
///   was_correct boolean not null,
///   time_taken_ms int not null,
///   points int not null,
///   submitted_at timestamptz default now(),
///   primary key (duel_code, player_id, question_index)
/// );
///
/// alter publication supabase_realtime add table duels;
/// alter publication supabase_realtime add table duel_answers;
/// ```
class DuelRepository {
  DuelRepository(this._client);

  final SupabaseClient _client;

  /// Six-character code, easy to read aloud.
  static String generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // no I/O/L/0/1
    final rng = math.Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<DuelMatch> createDuel({required String hostId}) async {
    final code = generateCode();
    final seed = DateTime.now().millisecondsSinceEpoch;
    await _client.from('duels').insert({
      'code': code,
      'host_id': hostId,
      'question_seed': seed,
      'question_count': 5,
      'status': 'waiting',
    });
    return DuelMatch(
      code: code,
      hostId: hostId,
      guestId: null,
      questionSeed: seed,
      questionCount: 5,
      status: DuelStatus.waiting,
    );
  }

  Future<DuelMatch> joinDuel({
    required String code,
    required String guestId,
  }) async {
    final updated = await _client
        .from('duels')
        .update({'guest_id': guestId, 'status': 'playing'})
        .eq('code', code.toUpperCase())
        .isFilter('guest_id', null)
        .select()
        .maybeSingle();
    if (updated == null) {
      throw const DuelException('Code unbekannt oder Lobby besetzt.');
    }
    return DuelMatch.fromRow(updated);
  }

  Stream<DuelMatch> watchDuel(String code) {
    return _client
        .from('duels')
        .stream(primaryKey: ['code'])
        .eq('code', code)
        .map((rows) => rows.isEmpty
            ? throw const DuelException('Lobby beendet.')
            : DuelMatch.fromRow(rows.first));
  }

  Stream<List<DuelAnswer>> watchAnswers(String code) {
    return _client
        .from('duel_answers')
        .stream(primaryKey: ['duel_code', 'player_id', 'question_index'])
        .eq('duel_code', code)
        .map((rows) => rows.map(DuelAnswer.fromRow).toList());
  }

  Future<void> submitAnswer({
    required String code,
    required String playerId,
    required int questionIndex,
    required int selectedIndex,
    required bool wasCorrect,
    required Duration timeTaken,
    required int points,
  }) async {
    await _client.from('duel_answers').upsert({
      'duel_code': code,
      'player_id': playerId,
      'question_index': questionIndex,
      'selected_index': selectedIndex,
      'was_correct': wasCorrect,
      'time_taken_ms': timeTaken.inMilliseconds,
      'points': points,
    });
  }

  Future<void> finish(String code) async {
    await _client.from('duels').update({'status': 'finished'}).eq('code', code);
  }

  /// Build the same question set both players see, given the seed.
  List<Question> resolveQuestions(int seed,
      {required QuestionRepository questions, int count = 5}) {
    return questions.randomBatch(count: count, seed: seed);
  }
}

class DuelException implements Exception {
  const DuelException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum DuelStatus { waiting, playing, finished }

class DuelMatch {
  const DuelMatch({
    required this.code,
    required this.hostId,
    required this.guestId,
    required this.questionSeed,
    required this.questionCount,
    required this.status,
  });

  final String code;
  final String hostId;
  final String? guestId;
  final int questionSeed;
  final int questionCount;
  final DuelStatus status;

  bool get hasGuest => guestId != null;

  factory DuelMatch.fromRow(Map<String, dynamic> r) => DuelMatch(
        code: r['code'] as String,
        hostId: r['host_id'] as String,
        guestId: r['guest_id'] as String?,
        questionSeed: (r['question_seed'] as num).toInt(),
        questionCount: (r['question_count'] as num).toInt(),
        status: DuelStatus.values.firstWhere(
          (s) => s.name == r['status'],
          orElse: () => DuelStatus.waiting,
        ),
      );
}

class DuelAnswer {
  const DuelAnswer({
    required this.duelCode,
    required this.playerId,
    required this.questionIndex,
    required this.selectedIndex,
    required this.wasCorrect,
    required this.timeTaken,
    required this.points,
  });

  final String duelCode;
  final String playerId;
  final int questionIndex;
  final int selectedIndex;
  final bool wasCorrect;
  final Duration timeTaken;
  final int points;

  factory DuelAnswer.fromRow(Map<String, dynamic> r) => DuelAnswer(
        duelCode: r['duel_code'] as String,
        playerId: r['player_id'] as String,
        questionIndex: (r['question_index'] as num).toInt(),
        selectedIndex: (r['selected_index'] as num).toInt(),
        wasCorrect: r['was_correct'] as bool,
        timeTaken: Duration(milliseconds: (r['time_taken_ms'] as num).toInt()),
        points: (r['points'] as num).toInt(),
      );
}
