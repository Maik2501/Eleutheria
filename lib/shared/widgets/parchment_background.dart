import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Paints a subtle warm gradient + soft noise to evoke aged parchment.
///
/// Lightweight (custom painter, no images) so it stays smooth at 120Hz.
class ParchmentBackground extends StatelessWidget {
  const ParchmentBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.6),
                radius: 1.4,
                colors: [
                  palette.page,
                  palette.parchment,
                ],
                stops: const [0.0, 0.85],
              ),
            ),
            child: const CustomPaint(
              isComplex: true,
              willChange: false,
              painter: _GrainPainter(seed: 7, opacity: 0.025),
              child: SizedBox.expand(),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.seed, required this.opacity});

  final int seed;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..color = AppColors.ink.withValues(alpha: opacity);
    final count = (size.width * size.height / 1400).round();
    for (var i = 0; i < count; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.8 + 0.2;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}
