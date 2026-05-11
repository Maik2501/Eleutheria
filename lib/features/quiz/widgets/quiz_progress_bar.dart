import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Slim progress indicator that animates as questions advance.
class QuizProgressBar extends StatelessWidget {
  const QuizProgressBar({
    super.key,
    required this.progress,
    this.timerProgress,
  });

  /// 0..1
  final double progress;

  /// 0..1 — optional countdown overlay; reset per question.
  final double? timerProgress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: palette.parchment,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.divider, width: 0.5),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress.clamp(0, 1).toDouble(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.gold, AppColors.goldDeep],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (timerProgress != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor:
                      (1 - timerProgress!.clamp(0, 1)).toDouble(),
                  child: Container(
                    color: palette.incorrect.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
