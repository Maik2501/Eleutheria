import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for Sophia.
///
/// Display uses Fraunces (warm serif with optical sizing) for headlines and quotes,
/// body uses Inter for legibility.
class AppTypography {
  AppTypography._();

  static TextTheme build(Color ink, Color inkSoft) {
    final display = GoogleFonts.frauncesTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontSize: 48,
        height: 1.05,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.2,
        color: ink,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontSize: 36,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        color: ink,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: ink,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: inkSoft,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: ink,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: ink,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        color: inkSoft,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: ink,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: inkSoft,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: inkSoft,
      ),
    );
  }

  /// Used for actual quote rendering — italicized Fraunces.
  static TextStyle quote(Color color) => GoogleFonts.fraunces(
        fontSize: 24,
        height: 1.4,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: color,
      );

  /// Used for chapter labels, eyebrow text.
  static TextStyle eyebrow(Color color) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.4,
        color: color,
      );

  /// Display / serif text style. Use for titles, scores, ornamental numerals.
  /// Routes through GoogleFonts so the font is actually resolved at runtime —
  /// raw `fontFamily: 'Fraunces'` falls back to the system font because the
  /// google_fonts package registers under `Fraunces_<variant>` internally.
  static TextStyle serif({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  /// Body / sans text style. Counterpart to [serif].
  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  /// CTA button label style. Slightly tracked, balanced weight — gives buttons
  /// a confident, set-in-type feel rather than a generic UI label.
  static TextStyle button({Color? color, double fontSize = 15.5}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.0,
        color: color,
      );
}
