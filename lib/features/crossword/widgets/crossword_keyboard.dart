import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// On-screen keyboard. Touch-first, no system keyboard required.
class CrosswordKeyboard extends StatelessWidget {
  const CrosswordKeyboard({
    super.key,
    required this.onLetter,
    required this.onBackspace,
    required this.onReveal,
  });

  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;

  /// Long-press the backspace = reveal active word.
  final VoidCallback onReveal;

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P', 'Ü'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ö', 'Ä'],
    ['Y', 'X', 'C', 'V', 'B', 'N', 'M', 'ß'],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      color: palette.parchment.withValues(alpha: 0.96),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final letter in row)
                    Expanded(
                      child: _Key(
                        label: letter,
                        onTap: () => onLetter(letter),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _Key(
                  label: 'Aufgeben',
                  onTap: onReveal,
                  ghost: true,
                ),
              ),
              Expanded(
                flex: 2,
                child: _Key(
                  label: '⌫',
                  onTap: onBackspace,
                  emphasis: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    this.emphasis = false,
    this.ghost = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasis;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: ghost
                  ? Colors.transparent
                  : (emphasis
                      ? palette.burgundy
                      : palette.page),
              border: Border.all(
                color: ghost ? palette.divider : palette.ink.withValues(alpha: 0.3),
                width: ghost ? 1 : 0.6,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: ghost
                  ? AppTypography.sans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.2,
                      color: palette.inkMuted,
                    )
                  : AppTypography.serif(
                      fontWeight: FontWeight.w700,
                      fontSize: emphasis ? 18 : 17,
                      color: emphasis ? AppColors.page : palette.ink,
                      height: 1.0,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
