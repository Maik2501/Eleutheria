import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// One answer choice — handles selection, reveal, elimination via 50/50.
class AnswerOptionButton extends StatelessWidget {
  const AnswerOptionButton({
    super.key,
    required this.label,
    required this.optionLetter,
    required this.onTap,
    required this.isSelected,
    required this.isCorrect,
    required this.isRevealed,
    required this.isEliminated,
  });

  final String label;

  /// 'A', 'B', 'C', 'D' — used as the leading marker.
  final String optionLetter;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isCorrect;
  final bool isRevealed;
  final bool isEliminated;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final state = _resolveState();
    final colors = _colorsForState(state, palette);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isEliminated ? 0.32 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEliminated || isRevealed ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border, width: 1.3),
              boxShadow: state == _OptionState.selectedPending
                  ? [
                      BoxShadow(
                        color: palette.burgundy.withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.markerBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.markerBorder, width: 1.2),
                  ),
                  child: Text(
                    optionLetter,
                    style: AppTypography.serif(
                      fontWeight: FontWeight.w700,
                      color: colors.markerText,
                      fontSize: 14,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.sans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: colors.text,
                      letterSpacing: -0.05,
                    ),
                  ),
                ),
                if (state == _OptionState.revealedCorrect) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_rounded, color: colors.text, size: 20),
                ] else if (state == _OptionState.revealedSelectedWrong) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.close_rounded, color: colors.text, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _OptionState _resolveState() {
    if (!isRevealed) {
      return isSelected ? _OptionState.selectedPending : _OptionState.idle;
    }
    if (isCorrect) return _OptionState.revealedCorrect;
    if (isSelected) return _OptionState.revealedSelectedWrong;
    return _OptionState.revealedNeutral;
  }

  _OptionColors _colorsForState(_OptionState s, AppPalette p) {
    switch (s) {
      case _OptionState.idle:
        return _OptionColors(
          background: p.page,
          border: p.divider,
          markerBackground: p.parchment,
          markerBorder: p.divider,
          markerText: p.inkMuted,
          text: p.ink,
        );
      case _OptionState.selectedPending:
        return _OptionColors(
          background: p.burgundy.withValues(alpha: 0.06),
          border: p.burgundy,
          markerBackground: p.burgundy,
          markerBorder: p.burgundy,
          markerText: AppColors.page,
          text: p.ink,
        );
      case _OptionState.revealedCorrect:
        return _OptionColors(
          background: p.correct.withValues(alpha: 0.12),
          border: p.correct,
          markerBackground: p.correct,
          markerBorder: p.correct,
          markerText: AppColors.page,
          text: p.correct,
        );
      case _OptionState.revealedSelectedWrong:
        return _OptionColors(
          background: p.incorrect.withValues(alpha: 0.10),
          border: p.incorrect,
          markerBackground: p.incorrect,
          markerBorder: p.incorrect,
          markerText: AppColors.page,
          text: p.incorrect,
        );
      case _OptionState.revealedNeutral:
        return _OptionColors(
          background: p.page,
          border: p.divider,
          markerBackground: p.parchment,
          markerBorder: p.divider,
          markerText: p.inkMuted,
          text: p.inkMuted,
        );
    }
  }
}

enum _OptionState {
  idle,
  selectedPending,
  revealedCorrect,
  revealedSelectedWrong,
  revealedNeutral,
}

class _OptionColors {
  const _OptionColors({
    required this.background,
    required this.border,
    required this.markerBackground,
    required this.markerBorder,
    required this.markerText,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color markerBackground;
  final Color markerBorder;
  final Color markerText;
  final Color text;
}
