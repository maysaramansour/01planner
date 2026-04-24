import 'package:flutter/material.dart';

class AppPalette {
  // Light
  static const Color background = Color(0xFFF4F2F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0EDED);
  static const Color primary = Color(0xFFE89F94);
  static const Color primaryMuted = Color(0xFFF5D5D0);
  static const Color secondary = Color(0xFFB58F8A);
  static const Color tertiary = Color(0xFFE8B89A);
  static const Color error = Color(0xFFCF6679);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF8E8E93);

  // Dark
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2E);
  static const Color darkOnSurface = Color(0xFFF2F2F2);
  static const Color darkOnSurfaceVariant = Color(0xFF8E8E93);
  static const Color darkTertiary = Color(0xFF6BA4D6);
}

class AppTheme {
  static ThemeData light(Locale locale, int primaryColorValue) =>
      _build(
          arabic: locale.languageCode == 'ar',
          primary: Color(primaryColorValue),
          brightness: Brightness.light);

  static ThemeData dark(Locale locale, int primaryColorValue) =>
      _build(
          arabic: locale.languageCode == 'ar',
          primary: Color(primaryColorValue),
          brightness: Brightness.dark);

  /// Backwards-compatible — defaults to light theme.
  static ThemeData of(Locale locale, int primaryColorValue) =>
      light(locale, primaryColorValue);

  static Color _deriveMuted(Color primary, Brightness b) {
    final hsl = HSLColor.fromColor(primary);
    final adjust = b == Brightness.light ? 0.18 : -0.22;
    return hsl
        .withLightness((hsl.lightness + adjust).clamp(0.0, 0.95))
        .toColor();
  }

  static ThemeData _build({
    required bool arabic,
    required Color primary,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final muted = _deriveMuted(primary, brightness);

    final background = isDark ? AppPalette.darkBackground : AppPalette.background;
    final surface = isDark ? AppPalette.darkSurface : AppPalette.surface;
    final surfaceVariant =
        isDark ? AppPalette.darkSurfaceVariant : AppPalette.surfaceVariant;
    final onSurface = isDark ? AppPalette.darkOnSurface : AppPalette.onSurface;
    final onSurfaceVariant =
        isDark ? AppPalette.darkOnSurfaceVariant : AppPalette.onSurfaceVariant;
    final tertiary = isDark ? AppPalette.darkTertiary : AppPalette.tertiary;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: Colors.white,
            primaryContainer: muted,
            onPrimaryContainer: onSurface,
            secondary: AppPalette.secondary,
            onSecondary: Colors.white,
            tertiary: tertiary,
            onTertiary: Colors.white,
            surface: surface,
            onSurface: onSurface,
            surfaceContainerHighest: surfaceVariant,
            onSurfaceVariant: onSurfaceVariant,
            error: AppPalette.error,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            primaryContainer: muted,
            onPrimaryContainer: onSurface,
            secondary: AppPalette.secondary,
            onSecondary: Colors.white,
            tertiary: tertiary,
            onTertiary: Colors.white,
            surface: surface,
            onSurface: onSurface,
            surfaceContainerHighest: surfaceVariant,
            onSurfaceVariant: onSurfaceVariant,
            error: AppPalette.error,
          );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
    );

    final fontFamily = arabic ? 'Cairo' : 'Inter';
    final textTheme = base.textTheme.apply(fontFamily: fontFamily);

    return base.copyWith(
      textTheme: textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? Colors.white : primary,
        foregroundColor: isDark ? AppPalette.darkBackground : Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerTheme: DividerThemeData(
        color: surfaceVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: onSurface,
        textColor: onSurface,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
