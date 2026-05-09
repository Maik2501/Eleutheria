import 'package:flutter/material.dart';

/// Warm Academia palette — inspired by old libraries, parchment, ink and gold.
class AppColors {
  AppColors._();

  // — Light (default) —
  static const parchment = Color(0xFFF5EFE6);
  static const parchmentDeep = Color(0xFFEFE7D8);
  static const page = Color(0xFFFAF6EE);
  static const ink = Color(0xFF2A1810);
  static const inkSoft = Color(0xFF4A3528);
  static const inkMuted = Color(0xFF8A7563);

  static const burgundy = Color(0xFF6B2737);
  static const burgundyDeep = Color(0xFF4A1A26);
  static const burgundySoft = Color(0xFF8C3A4D);

  static const gold = Color(0xFFC9A961);
  static const goldDeep = Color(0xFFA88742);
  static const goldSoft = Color(0xFFE0C685);

  static const sage = Color(0xFF7A8B6F);
  static const terracotta = Color(0xFFC97B4A);

  // Semantic
  static const correct = Color(0xFF6B8E5A);
  static const incorrect = Color(0xFFB54B3D);
  static const hint = Color(0xFF7A8FA8);

  // — Dark (Salon) —
  static const darkBg = Color(0xFF1A1410);
  static const darkSurface = Color(0xFF241C16);
  static const darkSurfaceElevated = Color(0xFF2E251D);
  static const darkInk = Color(0xFFF0E6D2);
  static const darkInkMuted = Color(0xFFB8A98F);
}

/// Convenience access through the theme so widgets stay theme-aware.
extension ThemeColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Theme extension for our custom semantic colors.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.parchment,
    required this.page,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.burgundy,
    required this.gold,
    required this.correct,
    required this.incorrect,
    required this.hint,
    required this.divider,
  });

  final Color parchment;
  final Color page;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color burgundy;
  final Color gold;
  final Color correct;
  final Color incorrect;
  final Color hint;
  final Color divider;

  static const light = AppPalette(
    parchment: AppColors.parchment,
    page: AppColors.page,
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    inkMuted: AppColors.inkMuted,
    burgundy: AppColors.burgundy,
    gold: AppColors.gold,
    correct: AppColors.correct,
    incorrect: AppColors.incorrect,
    hint: AppColors.hint,
    divider: Color(0x1A2A1810),
  );

  static const dark = AppPalette(
    parchment: AppColors.darkBg,
    page: AppColors.darkSurface,
    ink: AppColors.darkInk,
    inkSoft: AppColors.darkInkMuted,
    inkMuted: AppColors.darkInkMuted,
    burgundy: AppColors.burgundySoft,
    gold: AppColors.goldSoft,
    correct: Color(0xFF8FB07F),
    incorrect: Color(0xFFD1715F),
    hint: Color(0xFF9AAEC4),
    divider: Color(0x33F0E6D2),
  );

  @override
  AppPalette copyWith({
    Color? parchment,
    Color? page,
    Color? ink,
    Color? inkSoft,
    Color? inkMuted,
    Color? burgundy,
    Color? gold,
    Color? correct,
    Color? incorrect,
    Color? hint,
    Color? divider,
  }) =>
      AppPalette(
        parchment: parchment ?? this.parchment,
        page: page ?? this.page,
        ink: ink ?? this.ink,
        inkSoft: inkSoft ?? this.inkSoft,
        inkMuted: inkMuted ?? this.inkMuted,
        burgundy: burgundy ?? this.burgundy,
        gold: gold ?? this.gold,
        correct: correct ?? this.correct,
        incorrect: incorrect ?? this.incorrect,
        hint: hint ?? this.hint,
        divider: divider ?? this.divider,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      parchment: Color.lerp(parchment, other.parchment, t)!,
      page: Color.lerp(page, other.page, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      burgundy: Color.lerp(burgundy, other.burgundy, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      correct: Color.lerp(correct, other.correct, t)!,
      incorrect: Color.lerp(incorrect, other.incorrect, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
