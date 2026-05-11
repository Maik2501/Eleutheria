import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/answer_input_style.dart';
import '../models/player_profile.dart';

/// Persists [PlayerProfile] in SharedPreferences as JSON. Lightweight enough
/// for our needs and avoids the build_runner roundtrip Hive would require.
class ProfileRepository {
  ProfileRepository(this._prefs);

  static const _key = 'player_profile_v1';
  final SharedPreferences _prefs;

  Future<PlayerProfile> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final p = PlayerProfile.fresh(
        id: const Uuid().v4(),
        displayName: 'Schülerin der Philosophie',
      );
      await save(p);
      return p;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _fromJson(json);
  }

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
        'unlockedAchievements': p.unlockedAchievements.toList(),
        'bookmarkedQuoteIds': p.bookmarkedQuoteIds.toList(),
        'preferredCategories': p.preferredCategories.toList(),
        'preferredDifficulty': [
          p.preferredDifficulty.$1,
          p.preferredDifficulty.$2
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
        unlockedAchievements:
            ((j['unlockedAchievements'] as List?)?.cast<String>() ?? const [])
                .toSet(),
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
}
