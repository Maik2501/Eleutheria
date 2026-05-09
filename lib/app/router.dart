import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/game_session.dart';
import '../data/models/question.dart';
import '../features/categories/categories_screen.dart';
import '../features/crossword/crossword_screen.dart';
import '../features/duel/duel_lobby_screen.dart';
import '../features/duel/duel_match_screen.dart';
import '../features/home/home_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
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
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (_, __) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
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
        builder: (_, __) => const QuizScreen(config: GameConfig.practiceDefault),
      ),
      GoRoute(
        path: '/play/category/:cat',
        builder: (_, state) {
          final name = state.pathParameters['cat']!;
          final cat = QuestionCategory.values
              .firstWhere((c) => c.name == name, orElse: () => QuestionCategory.quoteToPhilosopher);
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
        builder: (_, __) => const DuelLobbyScreen(),
      ),
      GoRoute(
        path: '/duel/:code',
        builder: (_, state) =>
            DuelMatchScreen(code: state.pathParameters['code']!),
      ),
      GoRoute(
        path: '/result',
        builder: (_, state) {
          final extras = state.extra as Map<String, dynamic>;
          return ResultScreen(
            session: extras['session'] as GameSession,
            xpGained: extras['xpGained'] as int,
            unlockedAchievements:
                (extras['unlockedAchievements'] as List).cast<String>(),
          );
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Pfad nicht gefunden: ${state.uri}')),
    ),
  );
});
