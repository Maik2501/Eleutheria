import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/question.dart';
import '../../data/seed/philosophers_seed.dart';
import '../../data/seed/questions_seed.dart';
import '../../shared/widgets/parchment_background.dart';
import '../../shared/widgets/philosopher_avatar.dart';

/// Persönliche Sammlung gemerkter Fragen. Bookmark-IDs leben im
/// PlayerProfile (`bookmarkedQuoteIds`), die zugehörigen Fragen werden
/// hier per Lookup aus dem Seed-Pool aufgelöst.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final profile = ref.watch(profileNotifierProvider).value;
    if (profile == null) return const SizedBox.shrink();

    final byId = {for (final q in kQuestions) q.id: q};
    // Reihenfolge: Neueste Bookmarks zuerst. Da `bookmarkedQuoteIds` ein
    // Set ist, das wir bei jedem Toggle neu konstruieren (siehe
    // ProfileNotifier.toggleBookmark), liegt die zuletzt hinzugefügte ID
    // bereits am Ende — wir kehren die Reihenfolge einmal um.
    final bookmarked = profile.bookmarkedQuoteIds
        .toList(growable: false)
        .reversed
        .map((id) => byId[id])
        .whereType<Question>()
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Lesezeichen'),
      ),
      body: ParchmentBackground(
        child: bookmarked.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                itemCount: bookmarked.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final q = bookmarked[i];
                  return _BookmarkCard(
                    question: q,
                    onRemove: () => ref
                        .read(profileNotifierProvider.notifier)
                        .toggleBookmark(q.id),
                  );
                },
              ),
      ),
      bottomNavigationBar: bookmarked.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Text(
                  '${bookmarked.length} ${bookmarked.length == 1 ? "Lesezeichen" : "Lesezeichen"}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.inkMuted,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({required this.question, required this.onRemove});

  final Question question;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final philosopher = question.philosopherId == null
        ? null
        : philosopherById[question.philosopherId];
    final isQuote = question.category == QuestionCategory.quoteToPhilosopher ||
        question.category == QuestionCategory.completeQuote;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.category.icon,
                style: TextStyle(
                  color: palette.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.category.label.toUpperCase(),
                  style: AppTypography.eyebrow(palette.inkMuted),
                ),
              ),
              IconButton(
                tooltip: 'Lesezeichen entfernen',
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.bookmark_rounded, color: palette.gold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Die "richtige Antwort" ist hier interessanter als der Prompt:
          // bei Quote-Fragen ist der Prompt das Zitat selbst (gut), bei
          // den Werk-/Konzept-Fragen ist die Antwort der Inhalt, den man
          // sich merken will. Wir zeigen Antwort als Headline, Prompt als
          // Untertitel.
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              isQuote ? question.prompt : question.correctAnswer,
              style: isQuote
                  ? AppTypography.quote(palette.ink).copyWith(
                      fontSize: 17,
                      height: 1.35,
                    )
                  : AppTypography.serif(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
            ),
          ),
          if (!isQuote) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                question.prompt,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.inkMuted,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (isQuote && question.attribution != null) ...[
            const SizedBox(height: 4),
            Text(
              '— ${question.attribution}',
              style: AppTypography.serif(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: palette.inkMuted,
              ),
            ),
          ],
          if (question.explanation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: palette.parchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✦',
                    style: TextStyle(color: palette.gold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: palette.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (philosopher != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                PhilosopherAvatar(
                  philosopher: philosopher,
                  size: 28,
                  borderRadius: 8,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        philosopher.name,
                        style: AppTypography.serif(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                      Text(
                        '${philosopher.years} · ${philosopher.school}',
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: palette.parchment,
                shape: BoxShape.circle,
                border: Border.all(color: palette.divider),
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 38,
                color: palette.gold,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Noch keine Lesezeichen',
              style: AppTypography.serif(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: palette.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe nach einer Antwort auf das Lesezeichen-Symbol, '
              'um Zitate und Werke hier zu sammeln.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.inkSoft,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
