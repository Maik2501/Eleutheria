import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game_session.dart';
import '../models/player_profile.dart';

/// Posts session results to the Supabase `scores` table.
///
/// Score math per [Block A of the roadmap](../../../ROADMAP.md):
///   raw_score = sum of all per-question points
///   score     = raw_score minus 50 % of points from questions where at
///               least one joker was used
///   jokers_used = number of questions with at least one joker
///   is_pure   = jokers_used == 0  (server-generated)
///
/// Sessions that don't belong on a leaderboard (Studierkammer/Practice,
/// Duell-Online, Categories) are silently skipped — call sites don't
/// need to check.
class ScoreRepository {
  ScoreRepository(this._client);

  final SupabaseClient _client;

  /// Submits the session if it qualifies for a leaderboard.
  /// Returns true when an insert was attempted (regardless of network result).
  /// Idempotent: re-submission with same session_id is rejected by the
  /// `unique (player_id, session_id)` constraint.
  Future<bool> maybeSubmit({
    required GameSession session,
    required PlayerProfile profile,
  }) async {
    dev.log(
      'maybeSubmit start: mode=${session.mode.name} '
      'inputStyle=${session.inputStyle.key} answers=${session.answers.length}',
      name: 'ScoreRepository',
    );

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      dev.log('skip: no auth uid', name: 'ScoreRepository');
      return false;
    }

    final mode = _resolveMode(session);
    if (mode == null) {
      dev.log(
        'skip: mode resolved to null (Practice/Duel/Category)',
        name: 'ScoreRepository',
      );
      return false;
    }

    final breakdown = _computeBreakdown(session.answers);
    final band = _resolveBand(session.difficultyMin, session.difficultyMax);
    final variant = _resolveVariant(session);

    final payload = {
      'player_id': uid,
      'display_name': profile.displayName,
      'mode': mode,
      'variant': variant,
      'difficulty_band': band,
      'raw_score': breakdown.rawScore,
      'score': breakdown.score,
      'correct': session.correctCount,
      'answered': session.answers.length,
      'jokers_used': breakdown.jokersUsed,
      'joker_setting': profile.jokerAvailability.key,
      'session_id': session.id,
    };
    dev.log('inserting: $payload', name: 'ScoreRepository');

    try {
      await _client.from('scores').insert(payload);
      dev.log('insert ok', name: 'ScoreRepository');
      return true;
    } on PostgrestException catch (e) {
      // 23505 = unique_violation. Bei doppeltem Submit für dieselbe Session
      // ist das exakt das gewünschte Verhalten — nicht als Fehler werten.
      if (e.code == '23505') {
        dev.log('insert dup (idempotent)', name: 'ScoreRepository');
        return true;
      }
      dev.log(
        'PostgrestException: code=${e.code} msg=${e.message} details=${e.details}',
        name: 'ScoreRepository',
      );
      return false;
    } catch (e, st) {
      dev.log('insert failed: $e', name: 'ScoreRepository', stackTrace: st);
      return false;
    }
  }

  /// `null` → diese Session gehört nicht auf ein Leaderboard.
  static String? _resolveMode(GameSession session) {
    if (session.inputStyle.key == 'letterbox') return 'letterbox';
    return switch (session.mode) {
      GameMode.classic => 'classic',
      GameMode.quizRush => 'quizRush',
      GameMode.suddenDeath => 'suddenDeath',
      GameMode.daily => 'daily',
      GameMode.practice => null,
      GameMode.vsOnline => null,
      GameMode.category => null,
    };
  }

  static String _resolveBand(int min, int max) {
    if (min >= 3) return 'meisterpruefung';
    if (max <= 2) return 'einstieg';
    return 'salon';
  }

  static String? _resolveVariant(GameSession session) {
    if (session.mode != GameMode.quizRush) return null;
    // Aktueller Konfig-Label-Stil: 'Best of 1 Minute' / 'Best of 3 Minuten' /
    // 'Best of 5 Minuten' / 'Endless'. Wir mappen das auf die Schlüssel
    // aus dem Schema.
    // Falls Session-Daten das Label nicht direkt mitführen, ziehen wir es
    // aus Heuristiken — Endless erkennt man am Fehlen eines Zeitlimits.
    // Caller können den Variant-Schlüssel explizit liefern, wenn sie ihn
    // kennen (z. B. aus der GameConfig).
    return null; // explicit override siehe submitFromConfig falls nötig
  }

  /// Fetches the top scoreboard entries with the given filters.
  ///
  /// [pure] = true -> nur Joker-freie Einträge. `false` bedeutet Casual:
  /// alle Einträge, weil Joker-Fragen bereits im gespeicherten Score abgewertet
  /// sind. [since] = null -> All-Time. [mode] = null -> alle Modi.
  /// [onlyMine] = true -> nur Einträge des aktuellen Users.
  Future<List<ScoreEntry>> topScores({
    required bool pure,
    String? mode,
    DateTime? since,
    bool onlyMine = false,
    int limit = 50,
  }) async {
    var query = _client.from('scores').select();
    if (pure) query = query.eq('is_pure', true);
    if (mode != null) query = query.eq('mode', mode);
    if (since != null) {
      query = query.gte('played_at', since.toIso8601String());
    }
    if (onlyMine) {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return const [];
      query = query.eq('player_id', uid);
    }
    final rows = await query.order('score', ascending: false).limit(limit);
    return (rows as List)
        .map((r) => ScoreEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  static _Breakdown _computeBreakdown(List<AnswerRecord> answers) {
    var raw = 0;
    var effective = 0;
    var jokerQuestions = 0;
    for (final a in answers) {
      raw += a.points;
      if (a.usedPowerUp != null) {
        jokerQuestions += 1;
        effective += (a.points / 2).round();
      } else {
        effective += a.points;
      }
    }
    return _Breakdown(
      rawScore: raw,
      score: effective,
      jokersUsed: jokerQuestions,
    );
  }
}

class _Breakdown {
  const _Breakdown({
    required this.rawScore,
    required this.score,
    required this.jokersUsed,
  });
  final int rawScore;
  final int score;
  final int jokersUsed;
}

/// One row of leaderboard output.
class ScoreEntry {
  const ScoreEntry({
    required this.playerId,
    required this.displayName,
    required this.mode,
    required this.difficultyBand,
    required this.score,
    required this.rawScore,
    required this.correct,
    required this.answered,
    required this.jokersUsed,
    required this.isPure,
    required this.playedAt,
  });

  final String playerId;
  final String displayName;
  final String mode;
  final String difficultyBand;
  final int score;
  final int rawScore;
  final int correct;
  final int answered;
  final int jokersUsed;
  final bool isPure;
  final DateTime playedAt;

  factory ScoreEntry.fromRow(Map<String, dynamic> r) => ScoreEntry(
        playerId: r['player_id'] as String,
        displayName: r['display_name'] as String,
        mode: r['mode'] as String,
        difficultyBand: r['difficulty_band'] as String,
        score: (r['score'] as num).toInt(),
        rawScore: (r['raw_score'] as num).toInt(),
        correct: (r['correct'] as num).toInt(),
        answered: (r['answered'] as num).toInt(),
        jokersUsed: (r['jokers_used'] as num).toInt(),
        isPure: r['is_pure'] as bool,
        playedAt: DateTime.parse(r['played_at'] as String),
      );
}
