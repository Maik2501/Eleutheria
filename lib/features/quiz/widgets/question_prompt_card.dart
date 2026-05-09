import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/question.dart';

/// The "card" that frames the question prompt — quote, work title, etc.
///
/// Renders different visual treatments based on category:
///  - quoteToPhilosopher / completeQuote: large italic Fraunces with
///    decorative quotation marks
///  - workToAuthor: serif title in italics with rule beneath
///  - philosopherToEra: clean centered name
///  - others: question-style prompt
class QuestionPromptCard extends StatelessWidget {
  const QuestionPromptCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
  });

  final Question question;
  final int questionNumber;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KAPITEL $questionNumber / $totalQuestions',
                style: AppTypography.eyebrow(palette.gold),
              ),
              _DifficultyDots(value: question.difficulty),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            question.category.eyebrow.toUpperCase(),
            style: AppTypography.eyebrow(palette.inkMuted),
          ),
          const SizedBox(height: 16),
          _PromptBody(question: question),
        ],
      ),
    );
  }
}

class _PromptBody extends StatelessWidget {
  const _PromptBody({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    switch (question.category) {
      case QuestionCategory.quoteToPhilosopher:
      case QuestionCategory.completeQuote:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -22,
              left: -8,
              child: Text(
                '"',
                style: AppTypography.serif(
                  fontSize: 90,
                  color: palette.gold.withValues(alpha: 0.35),
                  height: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Text(
                question.prompt,
                textAlign: TextAlign.center,
                style: AppTypography.quote(palette.ink),
              ),
            ),
          ],
        );
      case QuestionCategory.workToAuthor:
        return Column(
          children: [
            Text(
              question.prompt,
              textAlign: TextAlign.center,
              style: AppTypography.serif(
                fontSize: 26,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: palette.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(width: 60, height: 1, color: palette.gold),
          ],
        );
      case QuestionCategory.philosopherToEra:
        return Text(
          question.prompt,
          textAlign: TextAlign.center,
          style: AppTypography.serif(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: palette.ink,
            letterSpacing: -0.4,
          ),
        );
      case QuestionCategory.conceptToSchool:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: palette.gold, width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: AppTypography.serif(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: palette.ink,
              letterSpacing: -0.2,
            ),
          ),
        );
      case QuestionCategory.whoCriticizedWhom:
        return Text(
          question.prompt,
          textAlign: TextAlign.center,
          style: AppTypography.sans(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: palette.ink,
            height: 1.45,
            letterSpacing: -0.1,
          ),
        );
    }
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? palette.gold
                  : palette.inkMuted.withValues(alpha: 0.25),
            ),
          ),
        );
      }),
    );
  }
}
