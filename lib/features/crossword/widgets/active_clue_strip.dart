import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/crossword_puzzle.dart';

/// Strip showing the currently-active clue, with prev/next chevrons.
class ActiveClueStrip extends StatelessWidget {
  const ActiveClueStrip({
    super.key,
    required this.activeWord,
    required this.activeNumber,
    required this.onPrev,
    required this.onNext,
  });

  final CrosswordWord activeWord;
  final int activeNumber;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dirLabel =
        activeWord.direction == WordDirection.across ? 'Waagerecht' : 'Senkrecht';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.page,
        border: Border(
          top: BorderSide(color: palette.divider),
          bottom: BorderSide(color: palette.divider),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '$activeNumber  ',
                      style: AppTypography.serif(
                        fontWeight: FontWeight.w700,
                        color: palette.gold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dirLabel.toUpperCase(),
                      style: AppTypography.sans(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        fontSize: 10,
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activeWord.clue,
                  style: AppTypography.serif(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: palette.ink,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
