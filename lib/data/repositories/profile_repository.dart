import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/answer_input_style.dart';
import '../models/player_profile.dart';

/// Persists [PlayerProfile] in SharedPreferences as JSON. Lightweight enough
/// for our needs and avoids the build_runner roundtrip Hive would require.
class ProfileRepository {
  ProfileRepository(this._prefs);

  static const _key = 'player_profile_v1';
  final SharedPreferences _prefs;

  /// Returns the Supabase auth UID if signed in, else null. We prefer this
  /// over a locally generated UUID so RLS-Policies can match `auth.uid()`.
  String? get _supabaseUid {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<PlayerProfile> load() async {
    final raw = _prefs.getString(_key);
    final authUid = _supabaseUid;

    if (raw == null) {
      final p = PlayerProfile.fresh(
        id: authUid ?? const Uuid().v4(),
        displayName: 'Schülerin der Philosophie',
      );
      await save(p);
      return p;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final existing = _fromJson(json);

    // Migration: war die App schon mal mit einer lokalen UUID gestartet und
    // bekommt jetzt eine Supabase-UID? Dann ID austauschen, Rest behalten.
    if (authUid != null && existing.id != authUid) {
      final migrated = _withId(existing, authUid);
      await save(migrated);
      return migrated;
    }
    return existing;
  }

  PlayerProfile _withId(PlayerProfile p, String newId) => PlayerProfile(
        id: newId,
        displayName: p.displayName,
        avatarSeal: p.avatarSeal,
        xp: p.xp,
        streakDays: p.streakDays,
        lastPlayedDate: p.lastPlayedDate,
        totalGamesPlayed: p.totalGamesPlayed,
        totalCorrect: p.totalCorrect,
        bestSuddenDeath: p.bestSuddenDeath,
        flawlessClassicCount: p.flawlessClassicCount,
        fastCorrectAnswers: p.fastCorrectAnswers,
        duelsWon: p.duelsWon,
        currentDuelStreak: p.currentDuelStreak,
        bestDuelStreak: p.bestDuelStreak,
        nightSessionsCount: p.nightSessionsCount,
        answeredEraKeys: p.answeredEraKeys,
        unlockedAchievements: p.unlockedAchievements,
        bookmarkedQuoteIds: p.bookmarkedQuoteIds,
        preferredCategories: p.preferredCategories,
        preferredDifficulty: p.preferredDifficulty,
        locale: p.locale,
        themeMode: p.themeMode,
        soundsEnabled: p.soundsEnabled,
        hapticsEnabled: p.hapticsEnabled,
        jokerAvailability: p.jokerAvailability,
        preferredInputStyle: p.preferredInputStyle,
      );

  Future<void> save(PlayerProfile p) async {
    await _prefs.setString(_key, jsonEncode(_toJson(p)));
  }

  static Map<String, dynamic> _toJson(PlayerProfile p) => {
        'id': p.id,
        'displayName': p.displayName,
        'avatarSeal': p.avatarSeal,
        'xp': p.xp,
        'streakDays': p.streakDays,
        'lastPlayedDate': p.lastPlayedDate?.toIso8601String(),
        'totalGamesPlayed': p.totalGamesPlayed,
        'totalCorrect': p.totalCorrect,
        'bestSuddenDeath': p.bestSuddenDeath,
        'flawlessClassicCount': p.flawlessClassicCount,
        'fastCorrectAnswers': p.fastCorrectAnswers,
        'duelsWon': p.duelsWon,
        'currentDuelStreak': p.currentDuelStreak,
        'bestDuelStreak': p.bestDuelStreak,
        'nightSessionsCount': p.nightSessionsCount,
        'answeredEraKeys': p.answeredEraKeys.toList(),
        'unlockedAchievements': p.unlockedAchievements.toList(),
        'bookmarkedQuoteIds': p.bookmarkedQuoteIds.toList(),
        'preferredCategories': p.preferredCategories.toList(),
        'preferredDifficulty': [
          p.preferredDifficulty.$1,
          p.preferredDifficulty.$2,
        ],
        'locale': p.locale,
        'themeMode': p.themeMode,
        'soundsEnabled': p.soundsEnabled,
        'hapticsEnabled': p.hapticsEnabled,
        'jokerAvailability': p.jokerAvailability.key,
        'preferredInputStyle': p.preferredInputStyle.key,
      };

  static PlayerProfile _fromJson(Map<String, dynamic> j) => PlayerProfile(
        id: j['id'] as String,
        displayName: j['displayName'] as String,
        avatarSeal: j['avatarSeal'] as String? ?? 'Σ',
        xp: (j['xp'] as num).toInt(),
        streakDays: (j['streakDays'] as num).toInt(),
        lastPlayedDate: j['lastPlayedDate'] != null
            ? DateTime.parse(j['lastPlayedDate'] as String)
            : null,
        totalGamesPlayed: (j['totalGamesPlayed'] as num).toInt(),
        totalCorrect: (j['totalCorrect'] as num).toInt(),
        bestSuddenDeath: (j['bestSuddenDeath'] as num).toInt(),
        flawlessClassicCount: (j['flawlessClassicCount'] as num?)?.toInt() ?? 0,
        fastCorrectAnswers: (j['fastCorrectAnswers'] as num?)?.toInt() ?? 0,
        duelsWon: (j['duelsWon'] as num?)?.toInt() ?? 0,
        currentDuelStreak: (j['currentDuelStreak'] as num?)?.toInt() ?? 0,
        bestDuelStreak: (j['bestDuelStreak'] as num?)?.toInt() ?? 0,
        nightSessionsCount: (j['nightSessionsCount'] as num?)?.toInt() ?? 0,
        answeredEraKeys:
            ((j['answeredEraKeys'] as List?)?.cast<String>() ?? const [])
                .toSet(),
        unlockedAchievements: _migrateLegacyAchievementIds(
          ((j['unlockedAchievements'] as List?)?.cast<String>() ?? const [])
              .toSet(),
        ),
        bookmarkedQuoteIds:
            ((j['bookmarkedQuoteIds'] as List?)?.cast<String>() ?? const [])
                .toSet(),
        preferredCategories:
            ((j['preferredCategories'] as List?)?.cast<String>() ?? const [])
                .toSet(),
        preferredDifficulty: () {
          final list =
              (j['preferredDifficulty'] as List?)?.cast<num>() ?? const [1, 5];
          return (list[0].toInt(), list[1].toInt());
        }(),
        locale: j['locale'] as String? ?? 'de',
        themeMode: j['themeMode'] as String? ?? 'system',
        soundsEnabled: j['soundsEnabled'] as bool? ?? false,
        hapticsEnabled: j['hapticsEnabled'] as bool? ?? true,
        jokerAvailability: JokerAvailability.fromKey(
          j['jokerAvailability'] as String?,
        ),
        preferredInputStyle: AnswerInputStyle.fromKey(
          j['preferredInputStyle'] as String?,
        ),
      );

  /// Translate persisted achievement IDs from the pre-tier era (one ID per
  /// threshold) to the new tier-id scheme (`<id>.<tier>`). Single-tier
  /// achievements kept their bare id and pass through untouched.
  ///
  /// Unknown legacy IDs survive as-is — the engine simply ignores them.
  static Set<String> _migrateLegacyAchievementIds(Set<String> stored) {
    if (stored.isEmpty) return stored;
    const map = <String, String>{
      'sokrates_student': 'correct_answers.bronze',
      'platos_apprentice': 'correct_answers.silver',
      'aristoteles_logician': 'correct_answers.gold',
      'streak_3': 'streaks.bronze',
      'streak_7': 'streaks.silver',
      'streak_30': 'streaks.gold',
      'sudden_death_10': 'sudden_death.bronze',
      'sudden_death_25': 'sudden_death.silver',
      'duel_streak_5': 'duel_streak.silver',
    };
    return {for (final id in stored) map[id] ?? id};
  }
}
