import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Das App-Icon (Wachssiegel mit Σ) in einem warmen Pergament-Rahmen
/// mit Gold-Verlauf und weichem Schatten. Wird im Home-Intro-Panel und
/// als Markenzeichen im Achievement-Gallery-Header verwendet.
class BrandSeal extends StatelessWidget {
  const BrandSeal({super.key, this.size = 104});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Inneres Padding und Bildradius skalieren mit der Größe, damit das
    // Verhältnis Rahmen-zu-Siegel konstant bleibt.
    final framePadding = size * 0.105;
    final outerRadius = size * 0.173;
    final innerRadius = size * 0.154;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerRadius),
          gradient: RadialGradient(
            center: const Alignment(-0.25, -0.35),
            colors: [
              palette.gold.withValues(alpha: 0.22),
              palette.parchment.withValues(alpha: 0.66),
            ],
          ),
          border: Border.all(color: palette.divider),
        ),
        child: Padding(
          padding: EdgeInsets.all(framePadding),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(innerRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(innerRadius),
              child: Image.asset(
                'assets/icons/app_icon.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
