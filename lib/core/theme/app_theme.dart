import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const palette = AppPalette.light;
    final textTheme = AppTypography.build(palette.ink, palette.inkSoft);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: palette.parchment,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: palette.burgundy,
        onPrimary: AppColors.page,
        secondary: palette.gold,
        onSecondary: palette.ink,
        tertiary: AppColors.sage,
        onTertiary: AppColors.page,
        error: palette.incorrect,
        onError: AppColors.page,
        surface: palette.page,
        onSurface: palette.ink,
        surfaceContainerHighest: palette.parchment,
        outline: palette.divider,
        shadow: AppColors.ink.withValues(alpha: 0.08),
      ),
      textTheme: textTheme,
      extensions: const [AppPalette.light],
      splashFactory: NoSplash.splashFactory,
      // pageTransitionsTheme bewusst nicht überschrieben: iOS bekommt
      // Cupertino-Übergänge ohnehin als Default. Der frühere Override
      // erzwang Cupertino auch auf Android, aber die explizite Referenz
      // auf CupertinoPageTransitionsBuilder bricht Codemagic-Builds (dortige
      // Flutter-Version exportiert die Klasse anders). Wir lassen Flutter
      // die plattformspezifischen Defaults wählen.
      appBarTheme: AppBarTheme(
        backgroundColor: palette.parchment,
        foregroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: palette.parchment,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.serif(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: palette.ink,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.page,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.divider, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.burgundy,
          foregroundColor: AppColors.page,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: palette.divider, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.burgundy,
          textStyle: AppTypography.button(fontSize: 14),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: palette.ink, size: 22),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.page),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const palette = AppPalette.dark;
    final textTheme = AppTypography.build(palette.ink, palette.inkSoft);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.parchment,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: palette.gold,
        onPrimary: AppColors.darkBg,
        secondary: palette.burgundy,
        onSecondary: palette.ink,
        tertiary: AppColors.sage,
        onTertiary: AppColors.darkBg,
        error: palette.incorrect,
        onError: AppColors.page,
        surface: palette.page,
        onSurface: palette.ink,
        surfaceContainerHighest: AppColors.darkSurfaceElevated,
        outline: palette.divider,
        shadow: Colors.black.withValues(alpha: 0.3),
      ),
      textTheme: textTheme,
      extensions: const [AppPalette.dark],
      splashFactory: NoSplash.splashFactory,
      // pageTransitionsTheme bewusst nicht überschrieben: iOS bekommt
      // Cupertino-Übergänge ohnehin als Default. Der frühere Override
      // erzwang Cupertino auch auf Android, aber die explizite Referenz
      // auf CupertinoPageTransitionsBuilder bricht Codemagic-Builds (dortige
      // Flutter-Version exportiert die Klasse anders). Wir lassen Flutter
      // die plattformspezifischen Defaults wählen.
      appBarTheme: AppBarTheme(
        backgroundColor: palette.parchment,
        foregroundColor: palette.ink,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: palette.parchment,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTypography.serif(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: palette.ink,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.page,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.divider, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.gold,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: palette.divider, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button(),
        ),
      ),
      iconTheme: IconThemeData(color: palette.ink, size: 22),
    );
  }
}
