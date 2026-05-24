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
///   is_pure   = joker_setting == 'off'  (server-generated, siehe
///               migration 0009 — vorher hieß "pure" nur, dass keine
///               Joker eingesetzt wurden, jetzt heißt es, dass von
///               vornherein keine angeboten waren)
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
      'input_style': session.inputStyle.key,
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
  ///
  /// Der `input_style` wird separat ins Insert geschrieben — Letterbox
  /// kollabiert den GameMode also nicht mehr.
  static String? _resolveMode(GameSession session) {
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

  /// Variant-Key für die Leaderboard-Filterung. Wird beim Session-Aufbau
  /// (GameSessionController._resolveVariantKey) auf die Session geschrieben
  /// und hier nur durchgereicht. `null` für Modi ohne Sub-Variante.
  static String? _resolveVariant(GameSession session) => session.variantKey;

  /// Holt die Top-Einträge der Bestenliste, dedupliziert auf einen Eintrag
  /// pro Spieler:in (jeweils der beste).
  ///
  /// - [pure] = true → nur Joker-freie Einträge.
  /// - [mode] = null → alle Modi; sonst exakte mode-Spalte.
  /// - [variant] = null → alle Varianten dieses Modus; sonst exakter Match.
  /// - [since] = null → All-Time.
  /// - [onlyMine] = true → nur eigene Einträge (Dedupe entfällt, weil's nur einen Spieler gibt).
  /// - [orderByCorrect] = true → primäre Sortierung nach `correct` statt `score`
  ///   (für Endless: dort sind Punkte irrelevant, es zählt die Anzahl der
  ///   richtigen Antworten).
  /// - Tiebreaker: `played_at` aufsteigend → wer den Wert zuerst erreicht hat,
  ///   steht oben.
  Future<List<ScoreEntry>> topScores({
    required bool pure,
    String? mode,
    String? variant,
    String? band,
    String? inputStyle,
    DateTime? since,
    bool onlyMine = false,
    bool orderByCorrect = false,
    int limit = 50,
  }) async {
    var query = _client.from('scores').select();
    if (pure) query = query.eq('is_pure', true);
    if (mode != null) query = query.eq('mode', mode);
    if (variant != null) query = query.eq('variant', variant);
    if (band != null) query = query.eq('difficulty_band', band);
    if (inputStyle != null) query = query.eq('input_style', inputStyle);
    if (since != null) {
      query = query.gte('played_at', since.toIso8601String());
    }
    if (onlyMine) {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return const [];
      query = query.eq('player_id', uid);
    }
    // Wir holen mehr Zeilen als nötig, damit nach dem Dedupe-Schritt genug
    // unique Spieler:innen für die Top-50 übrig bleiben.
    final rawLimit = onlyMine ? limit : (limit * 5).clamp(100, 500);
    final rows = orderByCorrect
        ? await query
            .order('correct', ascending: false)
            .order('played_at', ascending: true)
            .limit(rawLimit)
        : await query
            .order('score', ascending: false)
            .order('played_at', ascending: true)
            .limit(rawLimit);
    final entries = (rows as List)
        .map((r) => ScoreEntry.fromRow(r as Map<String, dynamic>))
        .toList();
    if (onlyMine) return entries.take(limit).toList();
    // Dedupe pro player_id — dank der Sortierung steht der beste Lauf
    // zuerst, der erste Treffer pro Spieler:in ist also automatisch der
    // anzuzeigende.
    final seen = <String>{};
    final out = <ScoreEntry>[];
    for (final e in entries) {
      if (seen.add(e.playerId)) {
        out.add(e);
        if (out.length >= limit) break;
      }
    }
    return out;
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
    required this.inputStyle,
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

  /// 'multipleChoice' | 'letterbox'. Vor Migration 0007 gab es Zeilen,
  /// in denen Letterbox den Mode überschrieben hat — die Migration setzt
  /// für diese Altzeilen input_style='letterbox' und stellt den
  /// ursprünglichen Mode aus der Variant wieder her.
  final String inputStyle;

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
        // Defensiv: Altzeilen ohne Spalte könnten beim Lese-Cache
        // theoretisch ohne Feld auftauchen.
        inputStyle: (r['input_style'] as String?) ?? 'multipleChoice',
        score: (r['score'] as num).toInt(),
        rawScore: (r['raw_score'] as num).toInt(),
        correct: (r['correct'] as num).toInt(),
        answered: (r['answered'] as num).toInt(),
        jokersUsed: (r['jokers_used'] as num).toInt(),
        isPure: r['is_pure'] as bool,
        playedAt: DateTime.parse(r['played_at'] as String),
      );
}
