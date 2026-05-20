import 'dart:async';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/answer_input_style.dart';
import '../../data/models/difficulty_band.dart';
import '../../data/models/duel_config.dart';
import '../../data/models/question.dart';
import '../../data/repositories/question_repository.dart';

/// A duel match. Schema lives in `supabase/migrations/0001_init.sql` and
/// gets extended by `0003_duel_modes.sql` with mode/time/lives/etc.
class DuelRepository {
  DuelRepository(this._client);

  final SupabaseClient _client;

  /// Six-character code, easy to read aloud.
  static String generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // no I/O/L/0/1
    final rng = math.Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<DuelMatch> createDuel({
    required String hostId,
    required DuelConfig config,
  }) async {
    final code = generateCode();
    final seed = DateTime.now().millisecondsSinceEpoch;
    final row = await _client
        .from('duels')
        .insert({
          'code': code,
          'host_id': hostId,
          'question_seed': seed,
          'question_count': config.questionCount,
          'status': 'waiting',
          'mode': config.mode.serverKey,
          'time_limit_seconds': config.timeLimitSeconds,
          'lives_per_player': config.livesPerPlayer,
          'input_style': config.inputStyle.key,
          'difficulty_band': config.difficultyBand.serverKey,
        })
        .select()
        .single();
    return DuelMatch.fromRow(row);
  }

  /// The guest joins and the server stamps `started_at` — that timestamp is
  /// the shared clock both clients use to compute remaining session time.
  Future<DuelMatch> joinDuel({
    required String code,
    required String guestId,
  }) async {
    final updated = await _client
        .from('duels')
        .update({
          'guest_id': guestId,
          'status': 'playing',
        })
        .eq('code', code.toUpperCase())
        .eq('status', 'waiting')
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
        .map(
          (rows) => rows.isEmpty
              ? throw const DuelException('Lobby beendet.')
              : DuelMatch.fromRow(rows.first),
        );
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
    await _client.rpc<void>(
      'submit_duel_answer',
      params: {
        'p_duel_code': code,
        'p_player_id': playerId,
        'p_question_index': questionIndex,
        'p_selected_index': selectedIndex,
        'p_was_correct': wasCorrect,
        'p_time_taken_ms': timeTaken.inMilliseconds,
        'p_points': points,
      },
    );
  }

  Future<void> finish(String code) async {
    await _client
        .from('duels')
        .update({'status': 'finished'})
        .eq('code', code)
        .eq('status', 'playing');
  }

  /// Host cancels an open lobby (or timeout expires).
  Future<void> cancel(String code) async {
    await _client
        .from('duels')
        .update({'status': 'cancelled'})
        .eq('code', code)
        .eq('status', 'waiting');
  }

  /// Creates a new duel with the same config as [original], then writes
  /// the new code onto the old duel's `rematch_code` column so the opposite
  /// player sees the invitation via their existing watchDuel subscription.
  Future<DuelMatch> createRematch({
    required DuelMatch original,
    required String hostId,
  }) async {
    final rematch = await createDuel(hostId: hostId, config: original.config);
    await _client
        .from('duels')
        .update({'rematch_code': rematch.code})
        .eq('code', original.code)
        .eq('status', 'finished')
        .isFilter('rematch_code', null);
    return rematch;
  }

  /// Build the same question set both players see, given the seed.
  /// Filtered by the difficulty band stored on the duel row.
  List<Question> resolveQuestions(
    int seed, {
    required QuestionRepository questions,
    int count = 100,
    DifficultyBand band = DifficultyBand.salon,
    bool letterboxFriendlyOnly = false,
  }) {
    return questions.randomBatch(
      count: count,
      seed: seed,
      minDifficulty: band.min,
      maxDifficulty: band.max,
      letterboxFriendlyOnly: letterboxFriendlyOnly,
    );
  }
}

class DuelException implements Exception {
  const DuelException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum DuelStatus { waiting, playing, finished, cancelled }

class DuelMatch {
  const DuelMatch({
    required this.code,
    required this.hostId,
    required this.guestId,
    required this.questionSeed,
    required this.questionCount,
    required this.status,
    required this.mode,
    required this.timeLimitSeconds,
    required this.livesPerPlayer,
    required this.inputStyle,
    required this.difficultyBand,
    required this.startedAt,
    required this.rematchCode,
  });

  final String code;
  final String hostId;
  final String? guestId;
  final int questionSeed;
  final int questionCount;
  final DuelStatus status;

  final DuelMode mode;
  final int? timeLimitSeconds;
  final int? livesPerPlayer;
  final AnswerInputStyle inputStyle;
  final DifficultyBand difficultyBand;
  final DateTime? startedAt;

  /// Set on this duel when a rematch is created — the new duel code.
  /// Watch this on both clients to surface the rematch invitation.
  final String? rematchCode;

  bool get hasGuest => guestId != null;

  DuelConfig get config => DuelConfig(
        mode: mode,
        timeLimitSeconds: timeLimitSeconds,
        livesPerPlayer: livesPerPlayer,
        inputStyle: inputStyle,
        difficultyBand: difficultyBand,
        questionCount: questionCount,
      );

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
        mode: DuelMode.fromKey(r['mode'] as String?),
        timeLimitSeconds: (r['time_limit_seconds'] as num?)?.toInt(),
        livesPerPlayer: (r['lives_per_player'] as num?)?.toInt(),
        inputStyle: AnswerInputStyle.fromKey(r['input_style'] as String?),
        difficultyBand: _bandFromKey(r['difficulty_band'] as String?),
        startedAt: r['started_at'] == null
            ? null
            : DateTime.parse(r['started_at'] as String).toUtc(),
        rematchCode: r['rematch_code'] as String?,
      );

  static DifficultyBand _bandFromKey(String? key) =>
      DifficultyBand.values.firstWhere(
        (b) => b.serverKey == key,
        orElse: () => DifficultyBand.salon,
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
    required this.submittedAt,
  });

  final String duelCode;
  final String playerId;
  final int questionIndex;
  final int selectedIndex;
  final bool wasCorrect;
  final Duration timeTaken;
  final int points;

  /// Server-side timestamp (UTC) when this answer landed in `duel_answers`.
  /// Used by both clients as the shared clock for post-round pauses, since
  /// `now()` is set by Postgres in the insert and reaches both peers via
  /// the realtime stream.
  final DateTime submittedAt;

  factory DuelAnswer.fromRow(Map<String, dynamic> r) => DuelAnswer(
        duelCode: r['duel_code'] as String,
        playerId: r['player_id'] as String,
        questionIndex: (r['question_index'] as num).toInt(),
        selectedIndex: (r['selected_index'] as num).toInt(),
        wasCorrect: r['was_correct'] as bool,
        timeTaken: Duration(milliseconds: (r['time_taken_ms'] as num).toInt()),
        points: (r['points'] as num).toInt(),
        submittedAt: r['submitted_at'] == null
            ? DateTime.now().toUtc()
            : DateTime.parse(r['submitted_at'] as String).toUtc(),
      );
}
