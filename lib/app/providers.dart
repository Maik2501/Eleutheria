import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/answer_input_style.dart';
import '../data/models/difficulty_band.dart';
import '../data/models/game_session.dart';
import '../data/models/player_profile.dart';
import '../data/models/player_stats.dart';
import '../data/repositories/content_repository.dart';
import '../data/repositories/feedback_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/question_history_repository.dart';
import '../data/repositories/question_repository.dart';
import '../data/repositories/score_repository.dart';
import '../data/repositories/supabase_profile_repository.dart';
import '../data/seed/questions_seed.dart';
import '../data/models/question.dart';
import '../features/crossword/models/crossword_puzzle.dart';
import '../features/crossword/models/puzzle_seed.dart';
import '../data/seed/philosophers_seed.dart';
import '../data/services/achievement_engine.dart';
import '../env.dart';

/// Set during bootstrap in main.dart, then injected via override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(sharedPreferencesProvider)),
);

/// Aktueller Pool an Fragen — initial das gebundlete Set, wird vom
/// [contentBootstrapProvider] zur Laufzeit auf Cache- oder Remote-Daten
/// umgeschaltet. Sessions, die bereits laufen, behalten ihren ursprünglich
/// gesampelten Batch (siehe GameSessionController), ein Pool-Update
/// ändert also nichts mid-game.
final questionPoolProvider =
    StateProvider<List<Question>>((ref) => kQuestions);

/// Spiegelt das gleiche Schema für Crossword-Puzzles.
final crosswordPoolProvider =
    StateProvider<List<CrosswordPuzzle>>((ref) => kCrosswordPuzzles);

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(pool: ref.watch(questionPoolProvider)),
);

final contentCacheProvider = Provider<ContentCache>(
  (ref) => ContentCache(ref.watch(sharedPreferencesProvider)),
);

final remoteContentRepositoryProvider =
    Provider<RemoteContentRepository?>((ref) {
  if (!Env.hasSupabase) return null;
  try {
    return RemoteContentRepository(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

/// Einmaliger Bootstrap: liest erst den Cache (sofort verfügbar, blockt
/// nichts), versucht dann den Remote-Pull. Bei Erfolg wird Cache + Pool
/// aktualisiert. Bei Fehler bleibt der vorherige State erhalten — die App
/// läuft im schlimmsten Fall mit Bundle weiter.
///
/// Reihenfolge der Quellen: **Cache → Remote → Bundle (initial)**.
final contentBootstrapProvider = FutureProvider<void>((ref) async {
  final cache = ref.read(contentCacheProvider);

  // Schritt 1: Cache hydraten (synchron, sofort).
  final cachedQs = cache.readQuestions();
  if (cachedQs != null && cachedQs.isNotEmpty) {
    ref.read(questionPoolProvider.notifier).state = cachedQs;
  }
  final cachedPs = cache.readCrosswordPuzzles();
  if (cachedPs != null && cachedPs.isNotEmpty) {
    ref.read(crosswordPoolProvider.notifier).state = cachedPs;
  }

  // Schritt 2: Remote-Pull im Hintergrund. Fehler werden geschluckt — die
  // App bleibt mit Cache oder Bundle nutzbar.
  final remote = ref.read(remoteContentRepositoryProvider);
  if (remote == null) return;

  unawaited(() async {
    try {
      final qs = await remote.fetchQuestions();
      if (qs.isNotEmpty) {
        await cache.writeQuestions(qs);
        ref.read(questionPoolProvider.notifier).state = qs;
      }
    } catch (e, st) {
      dev.log('remote questions fetch failed: $e',
          name: 'ContentBootstrap', stackTrace: st,);
    }
    try {
      final ps = await remote.fetchCrosswordPuzzles();
      if (ps.isNotEmpty) {
        await cache.writeCrosswordPuzzles(ps);
        ref.read(crosswordPoolProvider.notifier).state = ps;
      }
    } catch (e, st) {
      dev.log('remote crossword fetch failed: $e',
          name: 'ContentBootstrap', stackTrace: st,);
    }
  }());
});

/// Manueller Refresh-Eingang — wird von einem Tile in den Einstellungen
/// gefeuert. Lädt explizit beide Pools neu und aktualisiert Cache + State.
/// Wirft, wenn kein Repo verfügbar ist (kein Supabase), damit der Aufrufer
/// das in der UI zurückmelden kann.
///
/// Nimmt `WidgetRef`, weil aktuell nur aus der Settings-UI heraus aufgerufen.
/// Sollte später auch ein Notifier das brauchen, kann eine Sibling-Funktion
/// mit `Ref`-Signatur ergänzt werden — Body bleibt identisch.
Future<void> refreshRemoteContent(WidgetRef ref) async {
  final repo = ref.read(remoteContentRepositoryProvider);
  if (repo == null) {
    throw StateError('Kein Supabase-Repository verfügbar.');
  }
  final cache = ref.read(contentCacheProvider);
  final qs = await repo.fetchQuestions();
  if (qs.isNotEmpty) {
    await cache.writeQuestions(qs);
    ref.read(questionPoolProvider.notifier).state = qs;
  }
  final ps = await repo.fetchCrosswordPuzzles();
  if (ps.isNotEmpty) {
    await cache.writeCrosswordPuzzles(ps);
    ref.read(crosswordPoolProvider.notifier).state = ps;
  }
}

/// Per-device cache of which questions the player has answered correctly
/// and how recently. Read at session start by [GameSessionController] to
/// bias the sampler away from recently-correct questions; written back
/// on every answered question.
final questionHistoryRepositoryProvider =
    Provider<QuestionHistoryRepository>(
  (ref) => QuestionHistoryRepository(ref.watch(sharedPreferencesProvider)),
);

/// Repository für die Supabase-Profiles-Tabelle. `null` wenn Supabase
/// nicht konfiguriert ist — der Aufrufer muss damit umgehen.
final supabaseProfileRepositoryProvider =
    Provider<SupabaseProfileRepository?>((ref) {
  if (!Env.hasSupabase) return null;
  try {
    return SupabaseProfileRepository(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

/// Repository für die Supabase-`scores`-Tabelle. `null` wenn Supabase
/// nicht konfiguriert ist — Submits werden dann übersprungen.
final scoreRepositoryProvider = Provider<ScoreRepository?>((ref) {
  if (!Env.hasSupabase) return null;
  try {
    return ScoreRepository(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

/// Repository für die Supabase-`feedback`-Tabelle. `null` wenn Supabase
/// nicht konfiguriert ist — der Aufrufer muss in dem Fall die Feedback-UI
/// entsprechend dimmen / einen Fallback (mailto) anbieten.
final feedbackRepositoryProvider = Provider<FeedbackRepository?>((ref) {
  if (!Env.hasSupabase) return null;
  try {
    return FeedbackRepository(Supabase.instance.client);
  } catch (_) {
    return null;
  }
});

/// Lädt das Remote-Profil einmalig beim App-Start. Wird vom Router-Gate
/// ausgewertet, um zu entscheiden, ob die Profil-Setup-UI gezeigt werden muss.
///
/// Werte:
/// - `AsyncData(profile)` mit Daten → Setup ist erledigt, weiter zum Home
/// - `AsyncData(null)` → noch kein Remote-Profil, Setup-UI zeigen
/// - `AsyncData(null)` bei fehlendem Repo (kein Supabase) → Offline-Modus, kein Gate
/// - `AsyncError` → Netzwerkproblem, UI muss Retry anbieten
final remoteProfileProvider = FutureProvider<RemoteProfile?>((ref) async {
  final repo = ref.watch(supabaseProfileRepositoryProvider);
  if (repo == null) return null;
  return repo.fetchMine();
});

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

  Future<void> setDifficultyBand(DifficultyBand band) async {
    final p = state.value;
    if (p == null) return;
    p.preferredDifficulty = (band.min, band.max);
    await _persist(p);
  }

  Future<void> markGameplayHintSeen() async {
    final p = state.value;
    if (p == null || p.hasSeenGameplayHint) return;
    p.hasSeenGameplayHint = true;
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

  /// Apply [session]'s outcome to the persisted profile and run the
  /// achievement engine against the fresh stats. The returned list contains
  /// every tier the player just unlocked, in registry order (bronze before
  /// silver before gold per achievement) — the celebration UI can iterate it
  /// to stagger animations.
  ///
  /// [wonDuel] is the one signal that can't be inferred from the session
  /// alone — it's decided by the duel match screen comparing two players'
  /// scores.
  Future<List<UnlockedTier>> applySessionResult({
    required GameSession session,
    required int xpGained,
    bool wonDuel = false,
  }) async {
    final p = state.value;
    if (p == null) return const [];

    final correctAnswers = session.correctCount;
    final fastCorrect = session.answers
        .where((a) => a.wasCorrect && a.timeTaken.inMilliseconds < 3000)
        .length;
    final flawlessClassic = session.mode == GameMode.classic &&
        correctAnswers == session.questions.length &&
        session.questions.isNotEmpty;
    final suddenDeathStreak =
        session.mode == GameMode.suddenDeath ? correctAnswers : 0;

    // Era coverage — look up philosopher → era for each correctly answered
    // question that carries a philosopher id.
    final newEras = <String>{};
    for (final answer in session.answers) {
      if (!answer.wasCorrect) continue;
      final question = session.questions
          .where((q) => q.id == answer.questionId)
          .cast<dynamic>()
          .firstOrNull;
      final philId = question?.philosopherId as String?;
      if (philId == null) continue;
      final phil = philosopherById[philId];
      if (phil != null) newEras.add(phil.era.name);
    }

    // ───── 1. Stat updates ─────
    p.xp += xpGained;
    p.totalGamesPlayed += 1;
    p.totalCorrect += correctAnswers;
    p.fastCorrectAnswers += fastCorrect;
    if (flawlessClassic) p.flawlessClassicCount += 1;
    if (suddenDeathStreak > p.bestSuddenDeath) {
      p.bestSuddenDeath = suddenDeathStreak;
    }
    if (newEras.isNotEmpty) {
      p.answeredEraKeys = {...p.answeredEraKeys, ...newEras};
    }

    // Daily streak.
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

    // Hidden achievements piggyback off play time.
    if (today.hour < 4) p.nightSessionsCount += 1;

    // Duel counters.
    if (session.mode == GameMode.vsOnline) {
      if (wonDuel) {
        p.duelsWon += 1;
        p.currentDuelStreak += 1;
        if (p.currentDuelStreak > p.bestDuelStreak) {
          p.bestDuelStreak = p.currentDuelStreak;
        }
      } else {
        p.currentDuelStreak = 0;
      }
    }

    // ───── 2. Achievement engine ─────
    final stats = PlayerStats.fromProfile(p);
    final freshlyUnlocked =
        AchievementEngine.evaluate(profile: p, stats: stats);

    await _persist(p);
    return freshlyUnlocked;
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
