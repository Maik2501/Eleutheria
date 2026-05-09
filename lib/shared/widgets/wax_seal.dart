import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Small wax seal motif — used as a brand mark, chapter ornament, or
/// achievement badge.
class WaxSeal extends StatelessWidget {
  const WaxSeal({
    super.key,
    this.size = 56,
    this.symbol = 'Σ',
    this.color,
  });

  final double size;
  final String symbol;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.burgundy;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            Color.lerp(c, Colors.white, 0.18)!,
            c,
            Color.lerp(c, Colors.black, 0.25)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          symbol,
          style: AppTypography.serif(
            fontSize: size * 0.46,
            fontWeight: FontWeight.w700,
            color: Color.lerp(c, Colors.white, 0.85),
            height: 1,
          ),
        ),
      ),
    );
  }
}
