import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Small wax seal motif — used as a brand mark, chapter ornament, or
/// achievement badge.
///
/// Two rendering paths:
///   - [assetPath] given → renders the asset (PNG/WebP), clipped to a circle.
///     The asset is expected to already include the warm-academia medallion
///     framing (parchment, double rim, motif), so we don't overlay any wax
///     gradient. If the asset is missing at runtime, falls back to the
///     procedural seal so the UI never goes blank.
///   - no asset → procedural wax seal: radial gradient circle with the given
///     [symbol] glyph centered on it.
class WaxSeal extends StatelessWidget {
  const WaxSeal({
    super.key,
    this.size = 56,
    this.symbol = 'Σ',
    this.color,
    this.assetPath,
  });

  final double size;
  final String symbol;
  final Color? color;

  /// Optional asset path (e.g. `assets/icons/achievements/first_steps.webp`).
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return _AssetSeal(
        assetPath: assetPath!,
        size: size,
        fallbackSymbol: symbol,
        fallbackColor: color,
      );
    }
    return _GradientSeal(size: size, symbol: symbol, color: color);
  }
}

class _AssetSeal extends StatelessWidget {
  const _AssetSeal({
    required this.assetPath,
    required this.size,
    required this.fallbackSymbol,
    required this.fallbackColor,
  });

  final String assetPath;
  final double size;
  final String fallbackSymbol;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        // If the asset is missing (e.g. a new achievement landed before the
        // image batch caught up), gracefully fall back to the procedural seal.
        errorBuilder: (context, _, __) => _GradientSeal(
          size: size,
          symbol: fallbackSymbol,
          color: fallbackColor,
        ),
      ),
    );
  }
}

class _GradientSeal extends StatelessWidget {
  const _GradientSeal({
    required this.size,
    required this.symbol,
    required this.color,
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
