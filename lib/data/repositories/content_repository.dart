import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/crossword/models/crossword_puzzle.dart';
import '../models/question.dart';

/// Liest Fragen + Crossword-Puzzles aus den Supabase-Tabellen `questions`
/// und `crossword_puzzles` (siehe Migration 0010). Reine Reader-Klasse —
/// Schreiben passiert ausschließlich über das Push-Skript
/// `scripts/push_content_to_supabase.py` mit Service-Role-Key.
class RemoteContentRepository {
  RemoteContentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Question>> fetchQuestions() async {
    final rows = await _client.from('questions').select();
    return (rows as List)
        .map((r) => Question.tryFromJson(Map<String, dynamic>.from(r as Map)))
        .whereType<Question>()
        .toList(growable: false);
  }

  Future<List<CrosswordPuzzle>> fetchCrosswordPuzzles() async {
    final rows = await _client.from('crossword_puzzles').select();
    return (rows as List)
        .map((r) =>
            CrosswordPuzzle.tryFromJson(Map<String, dynamic>.from(r as Map)),)
        .whereType<CrosswordPuzzle>()
        .toList(growable: false);
  }
}

/// Speichert den letzten erfolgreich heruntergeladenen Pool als JSON in den
/// SharedPreferences. Bewusst nicht Hive: der Roundtrip ist eine einmalige
/// 50–100 KB-Operation pro Refresh, dafür reicht JSON+Prefs locker.
class ContentCache {
  ContentCache(this._prefs);

  static const _kQuestions = 'cached_questions_v1';
  static const _kPuzzles = 'cached_crossword_puzzles_v1';
  static const _kSyncedAt = 'cached_content_synced_at';

  final SharedPreferences _prefs;

  DateTime? get lastSyncedAt {
    final raw = _prefs.getString(_kSyncedAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Liest den Fragen-Cache. `null` wenn leer oder defekt (z. B. Schema-Bruch
  /// nach Update). `null` signalisiert dem Loader, dass das Bundle als
  /// Anfangswert verwendet werden soll.
  List<Question>? readQuestions() {
    final raw = _prefs.getString(_kQuestions);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      final out = decoded
          .map((j) =>
              Question.tryFromJson(Map<String, dynamic>.from(j as Map)),)
          .whereType<Question>()
          .toList(growable: false);
      return out.isEmpty ? null : out;
    } catch (e, st) {
      dev.log('cached questions corrupt: $e',
          name: 'ContentCache', stackTrace: st,);
      return null;
    }
  }

  Future<void> writeQuestions(List<Question> qs) async {
    final json = jsonEncode(qs.map((q) => q.toJson()).toList());
    await _prefs.setString(_kQuestions, json);
    await _prefs.setString(_kSyncedAt, DateTime.now().toIso8601String());
  }

  List<CrosswordPuzzle>? readCrosswordPuzzles() {
    final raw = _prefs.getString(_kPuzzles);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      final out = decoded
          .map((j) => CrosswordPuzzle.tryFromJson(
                Map<String, dynamic>.from(j as Map),
              ),)
          .whereType<CrosswordPuzzle>()
          .toList(growable: false);
      return out.isEmpty ? null : out;
    } catch (e, st) {
      dev.log('cached crossword puzzles corrupt: $e',
          name: 'ContentCache', stackTrace: st,);
      return null;
    }
  }

  Future<void> writeCrosswordPuzzles(List<CrosswordPuzzle> ps) async {
    final json = jsonEncode(ps.map((p) => p.toJson()).toList());
    await _prefs.setString(_kPuzzles, json);
    await _prefs.setString(_kSyncedAt, DateTime.now().toIso8601String());
  }

  Future<void> clear() async {
    await _prefs.remove(_kQuestions);
    await _prefs.remove(_kPuzzles);
    await _prefs.remove(_kSyncedAt);
  }
}
