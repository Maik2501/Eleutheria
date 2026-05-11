import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/answer_input_style.dart';
import '../data/models/player_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/question_repository.dart';

/// Set during bootstrap in main.dart, then injected via override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(sharedPreferencesProvider)),
);

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(),
);

/// Live, mutable player profile. Use [profileNotifierProvider.notifier] to
/// mutate; widgets watch this directly.
final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, PlayerProfile>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<PlayerProfile> {
  late ProfileRepository _repo;

  @override
  Future<PlayerProfile> build() async {
    _repo = ref.watch(profileRepositoryProvider);
    return _repo.load();
  }

  Future<void> _persist(PlayerProfile p) async {
    state = AsyncData(p);
    await _repo.save(p);
  }

  Future<void> renameTo(String newName) async {
    final p = state.value;
    if (p == null) return;
    p.displayName = newName.trim().isEmpty ? p.displayName : newName.trim();
    await _persist(p);
  }

  Future<void> setAvatarSeal(String symbol) async {
    final p = state.value;
    if (p == null) return;
    p.avatarSeal = symbol;
    await _persist(p);
  }

  Future<void> setLocale(String code) async {
    final p = state.value;
    if (p == null) return;
    p.locale = code;
    await _persist(p);
  }

  Future<void> setThemeMode(String mode) async {
    final p = state.value;
    if (p == null) return;
    p.themeMode = mode;
    await _persist(p);
  }

  Future<void> setHaptics(bool enabled) async {
    final p = state.value;
    if (p == null) return;
    p.hapticsEnabled = enabled;
    await _persist(p);
  }

  Future<void> setSounds(bool enabled) async {
    final p = state.value;
    if (p == null) return;
    p.soundsEnabled = enabled;
    await _persist(p);
  }

  Future<void> setJokerAvailability(String key) async {
    final p = state.value;
    if (p == null) return;
    p.jokerAvailability = JokerAvailability.fromKey(key);
    await _persist(p);
  }

  Future<void> setPreferredInputStyle(AnswerInputStyle style) async {
    final p = state.value;
    if (p == null) return;
    p.preferredInputStyle = style;
    await _persist(p);
  }

  Future<void> toggleBookmark(String questionId) async {
    final p = state.value;
    if (p == null) return;
    if (p.bookmarkedQuoteIds.contains(questionId)) {
      p.bookmarkedQuoteIds.remove(questionId);
    } else {
      p.bookmarkedQuoteIds = {...p.bookmarkedQuoteIds, questionId};
    }
    await _persist(p);
  }

  /// Apply session results to the profile: XP, streak, totals, achievements.
  /// Returns the achievement IDs unlocked by *this* session, for celebration UI.
  Future<List<String>> applySessionResult({
    required int xpGained,
    required int correctAnswers,
    required int suddenDeathStreak,
    required bool flawlessClassic,
    required bool wonDuel,
  }) async {
    final p = state.value;
    if (p == null) return const [];
    final unlocked = <String>[];

    p.xp += xpGained;
    p.totalGamesPlayed += 1;
    p.totalCorrect += correctAnswers;

    if (suddenDeathStreak > p.bestSuddenDeath) {
      p.bestSuddenDeath = suddenDeathStreak;
    }

    final today = DateTime.now();
    final last = p.lastPlayedDate;
    if (last == null) {
      p.streakDays = 1;
    } else {
      final lastDay = DateTime(last.year, last.month, last.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      final diff = todayDay.difference(lastDay).inDays;
      if (diff == 0) {
        // Same day, no streak change.
      } else if (diff == 1) {
        p.streakDays += 1;
      } else {
        p.streakDays = 1;
      }
    }
    p.lastPlayedDate = today;

    void unlock(String id) {
      if (!p.unlockedAchievements.contains(id)) {
        p.unlockedAchievements = {...p.unlockedAchievements, id};
        unlocked.add(id);
      }
    }

    if (p.totalGamesPlayed == 1) unlock('first_steps');
    if (p.totalCorrect >= 10) unlock('sokrates_student');
    if (p.totalCorrect >= 50) unlock('platos_apprentice');
    if (p.totalCorrect >= 100) unlock('aristoteles_logician');
    if (p.streakDays >= 3) unlock('streak_3');
    if (p.streakDays >= 7) unlock('streak_7');
    if (p.streakDays >= 30) unlock('streak_30');
    if (flawlessClassic) unlock('flawless_classic');
    if (suddenDeathStreak >= 10) unlock('sudden_death_10');
    if (suddenDeathStreak >= 25) unlock('sudden_death_25');
    if (wonDuel && !p.unlockedAchievements.contains('first_duel_won')) {
      unlock('first_duel_won');
    }

    final hour = DateTime.now().hour;
    if (hour < 4) unlock('midnight_thinker');

    await _persist(p);
    return unlocked;
  }
}

/// Resolved [ThemeMode] from the profile setting.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final p = ref.watch(profileNotifierProvider).value;
  return switch (p?.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});
