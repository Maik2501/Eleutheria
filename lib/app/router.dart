import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/game_session.dart';
import '../data/models/question.dart';
import '../data/services/achievement_engine.dart';
import '../features/achievements/achievement_gallery_screen.dart';
import '../features/crossword/crossword_screen.dart';
import '../features/duel/duel_lobby_screen.dart';
import '../features/duel/duel_match_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/onboarding/profile_gate.dart';
import '../features/profile/profile_screen.dart';
import '../features/quiz/game_session_controller.dart';
import '../features/quiz/quiz_screen.dart';
import '../features/result/result_screen.dart';
import '../features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const ProfileGate(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (_, __) => const AchievementGalleryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (_, __) => const LeaderboardScreen(),
      ),
      // /categories archived 2026-05-16 (Roadmap Block F).
      // CategoriesScreen + /play/category/:cat bleiben im Code, sind aber
      // nicht mehr aus dem UI erreichbar. Bei Reaktivierung als
      // inhaltliche Sammlungen neu gestalten, nicht 1:1 wiederherstellen.
      GoRoute(
        path: '/play',
        builder: (_, state) => QuizScreen(
          config: (state.extra as GameConfig?) ?? GameConfig.classicDefault,
        ),
      ),
      GoRoute(
        path: '/play/classic',
        builder: (_, __) => const QuizScreen(config: GameConfig.classicDefault),
      ),
      GoRoute(
        path: '/play/letterbox',
        builder: (_, __) =>
            const QuizScreen(config: GameConfig.letterboxDefault),
      ),
      GoRoute(
        path: '/crossword',
        builder: (_, __) => const CrosswordScreen(),
      ),
      GoRoute(
        path: '/play/sudden-death',
        builder: (_, __) =>
            const QuizScreen(config: GameConfig.suddenDeathDefault),
      ),
      GoRoute(
        path: '/play/daily',
        builder: (_, __) => const QuizScreen(config: GameConfig.dailyDefault),
      ),
      GoRoute(
        path: '/practice',
        builder: (_, __) =>
            const QuizScreen(config: GameConfig.practiceDefault),
      ),
      GoRoute(
        path: '/play/category/:cat',
        builder: (_, state) {
          final name = state.pathParameters['cat']!;
          final cat = QuestionCategory.values.firstWhere((c) => c.name == name,
              orElse: () => QuestionCategory.quoteToPhilosopher,);
          return QuizScreen(
            config: GameConfig(
              mode: GameMode.category,
              questionCount: 10,
              categories: {cat},
            ),
          );
        },
      ),
      GoRoute(
        path: '/duel',
        builder: (_, state) {
          final tab = state.extra is int ? state.extra as int : 0;
          return DuelLobbyScreen(initialTabIndex: tab);
        },
      ),
      GoRoute(
        path: '/duel/:code',
        builder: (_, state) =>
            DuelMatchScreen(code: state.pathParameters['code']!.toUpperCase()),
      ),
      GoRoute(
        path: '/result',
        builder: (_, state) {
          final extras = state.extra as Map<String, dynamic>;
          return ResultScreen(
            session: extras['session'] as GameSession,
            xpGained: extras['xpGained'] as int,
            unlockedAchievements:
                (extras['unlockedAchievements'] as List).cast<UnlockedTier>(),
          );
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Pfad nicht gefunden: ${state.uri}')),
    ),
  );
});
