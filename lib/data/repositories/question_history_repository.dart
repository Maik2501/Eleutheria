import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local per-device history of which questions the player has seen and
/// how recently they got them right. Used by [QuestionRepository] to
/// weight away from recently-correct questions when sampling new batches.
///
/// Lives in SharedPreferences as a JSON-encoded map keyed by question id.
/// FIFO-capped at [_maxEntries] so storage stays bounded even after
/// thousands of plays — when the cap is exceeded, the least-recently-seen
/// entries are evicted first.
///
/// Per-device only. A future Stage-2 upgrade would mirror this into a
/// `question_history` table on Supabase for cross-device persistence.
class QuestionHistoryRepository {
  QuestionHistoryRepository(this._prefs);

  static const _key = 'question_history_v1';
  static const _maxEntries = 500;

  final SharedPreferences _prefs;

  /// Snapshot of all known per-question stats. Cheap enough to call at
  /// session start (the only call site today). Returns an immutable view.
  Map<String, QuestionStat> all() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, QuestionStat.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {
      // Corrupt / older schema → start fresh rather than blow up.
      return const {};
    }
  }

  Future<void> markCorrect(String questionId) async {
    final now = DateTime.now().toUtc();
    await _update(
      questionId,
      (cur) => cur.copyWith(
        lastCorrectAt: now,
        lastSeenAt: now,
        correctCount: cur.correctCount + 1,
      ),
    );
  }

  Future<void> markWrong(String questionId) async {
    final now = DateTime.now().toUtc();
    await _update(
      questionId,
      (cur) => cur.copyWith(
        lastSeenAt: now,
        wrongCount: cur.wrongCount + 1,
      ),
    );
  }

  Future<void> clear() => _prefs.remove(_key);

  Future<void> _update(
    String id,
    QuestionStat Function(QuestionStat) updater,
  ) async {
    final map = Map<String, QuestionStat>.from(all());
    final existing = map[id] ?? QuestionStat.empty;
    map[id] = updater(existing);
    if (map.length > _maxEntries) {
      // FIFO eviction by lastSeenAt ascending — oldest first.
      final sorted = map.entries.toList()
        ..sort((a, b) => a.value.lastSeenAt.compareTo(b.value.lastSeenAt));
      while (sorted.length > _maxEntries) {
        map.remove(sorted.removeAt(0).key);
      }
    }
    final encoded =
        jsonEncode(map.map((k, v) => MapEntry(k, v.toJson())));
    await _prefs.setString(_key, encoded);
  }
}

/// Per-question history entry. Compact JSON keys to keep the
/// SharedPreferences blob small even at 500 entries.
class QuestionStat {
  const QuestionStat({
    required this.lastSeenAt,
    this.lastCorrectAt,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  /// Sentinel for "no record yet". Used as the seed in
  /// [QuestionHistoryRepository._update] so the updater can write a fresh
  /// row without a separate "exists?" check at the call site.
  static final empty = QuestionStat(
    lastSeenAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final DateTime lastSeenAt;
  final DateTime? lastCorrectAt;
  final int correctCount;
  final int wrongCount;

  QuestionStat copyWith({
    DateTime? lastSeenAt,
    DateTime? lastCorrectAt,
    int? correctCount,
    int? wrongCount,
  }) =>
      QuestionStat(
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        lastCorrectAt: lastCorrectAt ?? this.lastCorrectAt,
        correctCount: correctCount ?? this.correctCount,
        wrongCount: wrongCount ?? this.wrongCount,
      );

  Map<String, dynamic> toJson() => {
        'l': lastSeenAt.toIso8601String(),
        if (lastCorrectAt != null) 'c': lastCorrectAt!.toIso8601String(),
        'cc': correctCount,
        'wc': wrongCount,
      };

  factory QuestionStat.fromJson(Map<String, dynamic> j) => QuestionStat(
        lastSeenAt: DateTime.parse(j['l'] as String),
        lastCorrectAt: j['c'] is String
            ? DateTime.parse(j['c'] as String)
            : null,
        correctCount: (j['cc'] as num?)?.toInt() ?? 0,
        wrongCount: (j['wc'] as num?)?.toInt() ?? 0,
      );
}
