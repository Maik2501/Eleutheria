import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/philosopher.dart';

class PhilosopherAvatar extends StatelessWidget {
  const PhilosopherAvatar({
    super.key,
    required this.philosopher,
    this.size = 48,
    this.borderRadius = 12,
  });

  final Philosopher philosopher;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.parchment,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: palette.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        philosopher.imageAsset,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        semanticLabel: philosopher.name,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            _InitialAvatar(philosopher: philosopher),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.philosopher});

  final Philosopher philosopher;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final initial = String.fromCharCode(philosopher.name.runes.first);

    return ColoredBox(
      color: palette.parchment,
      child: Center(
        child: Text(
          initial,
          style: AppTypography.serif(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: palette.burgundy,
          ),
        ),
      ),
    );
  }
}
