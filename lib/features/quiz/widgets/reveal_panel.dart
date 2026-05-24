import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/question.dart';
import '../../../data/repositories/feedback_repository.dart';
import '../../../data/seed/philosophers_seed.dart';
import '../../../shared/widgets/philosopher_avatar.dart';
import '../../feedback/feedback_sheet.dart';

/// Bottom panel that animates in after answering — shows attribution,
/// short explanation, and a "Continue" CTA.
class RevealPanel extends ConsumerWidget {
  const RevealPanel({
    super.key,
    required this.question,
    required this.wasCorrect,
    required this.onContinue,
    required this.points,
  });

  final Question question;
  final bool wasCorrect;
  final int points;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final philosopher = question.philosopherId == null
        ? null
        : philosopherById[question.philosopherId];
    final bookmarked = ref
            .watch(profileNotifierProvider)
            .value
            ?.bookmarkedQuoteIds
            .contains(question.id) ??
        false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: palette.divider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  wasCorrect
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: wasCorrect ? palette.correct : palette.incorrect,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  wasCorrect ? 'Richtig!' : 'Leider falsch',
                  style: AppTypography.serif(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: wasCorrect ? palette.correct : palette.incorrect,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (wasCorrect)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: palette.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+$points',
                      style: AppTypography.serif(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.gold,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => ref
                      .read(profileNotifierProvider.notifier)
                      .toggleBookmark(question.id),
                  icon: Icon(
                    bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: palette.gold,
                  ),
                ),
                IconButton(
                  tooltip: 'Diese Frage melden',
                  onPressed: () => FeedbackSheet.show(
                    context,
                    type: FeedbackType.questionReport,
                    title: 'Diese Frage melden',
                    intro:
                        'Stimmt etwas mit dieser Frage nicht? Wähl eine Kategorie aus — ein erklärender Text hilft, ist aber freiwillig.',
                    categories: FeedbackCategory.questionReportOptions,
                    questionId: question.id,
                    questionPreview: question.prompt,
                    messageHint: 'Optional: weitere Details …',
                    messageOptional: true,
                  ),
                  icon: Icon(
                    Icons.flag_outlined,
                    color: palette.inkMuted,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.correctAnswer,
              style: AppTypography.serif(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: palette.ink,
                height: 1.25,
                letterSpacing: -0.3,
              ),
            ),
            if (question.attribution != null) ...[
              const SizedBox(height: 4),
              Text(
                '— ${question.attribution}',
                style: AppTypography.serif(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: palette.inkMuted,
                ),
              ),
            ],
            if (question.explanation != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.parchment,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✦',
                      style: TextStyle(color: palette.gold, fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.explanation!,
                        style: TextStyle(
                          fontSize: 14,
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
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: palette.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    PhilosopherAvatar(
                      philosopher: philosopher,
                      size: 40,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            philosopher.name,
                            style: AppTypography.serif(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '${philosopher.years} · ${philosopher.school}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Weiter'),
                iconAlignment: IconAlignment.end,
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.4,
          end: 0,
          duration: 380.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
