import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Eyebrow + title + optional dividing rule. The signature heading style
/// across all screens.
class ChapterHeading extends StatelessWidget {
  const ChapterHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.alignment = CrossAxisAlignment.start,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final t = Theme.of(context).textTheme;

    final textAlign = switch (alignment) {
      CrossAxisAlignment.center => TextAlign.center,
      CrossAxisAlignment.end => TextAlign.end,
      _ => TextAlign.start,
    };

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          eyebrow.toUpperCase(),
          textAlign: textAlign,
          style: AppTypography.eyebrow(palette.gold),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: textAlign,
          style: t.displaySmall,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: t.bodyMedium?.copyWith(color: palette.inkMuted),
          ),
        ],
      ],
    );
  }
}

/// Decorative horizontal rule with a centered diamond, like in old book pages.
class DecorativeRule extends StatelessWidget {
  const DecorativeRule({super.key, this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.palette.gold;
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Container(height: 1, color: c.withValues(alpha: 0.4))),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: 0.785398, // 45deg
            child: Container(width: 6, height: 6, color: c),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: c.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
