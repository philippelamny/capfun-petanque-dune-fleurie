import 'package:flutter/material.dart';

/// Brand palette lifted straight from the Cap Fun / pétanque badge logo:
/// the mascot's red ribbon, the boules' brushed steel, the boulodrome sand
/// and its terracotta cochonnet, and a gold spark for highlights.
class AppColors {
  AppColors._();

  static const capfunRed = Color(0xFFE4231F);
  static const capfunRedDeep = Color(0xFFA8180F);

  static const steel = Color(0xFF9AA1AA);
  static const steelLight = Color(0xFFC7CDD6);
  static const steelDark = Color(0xFF454B54);

  static const sand = Color(0xFFE3C08C);
  static const sandDeep = Color(0xFFC79A5E);

  static const cochonnet = Color(0xFFE2572B);
  static const spark = Color(0xFFF2A93B);

  static const cream = Color(0xFFFBF3E4);
  static const creamCard = Color(0xFFFFFCF6);
  static const creamDark = Color(0xFF1C140D);
  static const cardDark = Color(0xFF271C13);

  static const ink = Color(0xFF2B2118);
  static const inkLight = Color(0xFFF3E6D4);
  static const muted = Color(0xFF8A7A66);
  static const mutedDark = Color(0xFFB7A48C);
}

/// The countdown banner's own semantic progression (safe → warning →
/// urgent), tinted to sit comfortably next to the brand palette rather than
/// stock Material colours.
class RoundClockColors {
  RoundClockColors._();

  static const calm = Color(0xFF3F8F5F);
  static const warning = Color(0xFFD98324);
  static const urgent = AppColors.capfunRed;
  static const expired = Color(0xFF6B0F09);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.capfunRed,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.capfunRed,
    onPrimary: Colors.white,
    secondary: AppColors.steelDark,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.steelLight,
    onSecondaryContainer: const Color(0xFF20242A),
    tertiary: AppColors.sandDeep,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.sand,
    onTertiaryContainer: const Color(0xFF4A3410),
    surface: AppColors.creamCard,
    onSurface: AppColors.ink,
    surfaceContainerHighest: const Color(0xFFF1E4CB),
    outline: AppColors.muted,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.capfunRed,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFFFF6B5F),
    onPrimary: const Color(0xFF3A0A05),
    secondary: AppColors.steelLight,
    onSecondary: const Color(0xFF20242A),
    secondaryContainer: AppColors.steelDark,
    onSecondaryContainer: AppColors.steelLight,
    tertiary: AppColors.spark,
    onTertiary: const Color(0xFF4A3410),
    tertiaryContainer: const Color(0xFF5C4419),
    onTertiaryContainer: AppColors.sand,
    surface: AppColors.cardDark,
    onSurface: AppColors.inkLight,
    surfaceContainerHighest: const Color(0xFF32251A),
    outline: AppColors.mutedDark,
  );

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final background = isDark ? AppColors.creamDark : AppColors.cream;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.15)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.15),
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.2),
        valueIndicatorColor: scheme.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.steelDark : AppColors.ink,
        contentTextStyle: TextStyle(color: isDark ? AppColors.inkLight : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: 0.2)),
    );
  }
}
