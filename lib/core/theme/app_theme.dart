import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system: "Fresh Mint & Teal" — an emerald/teal palette with
/// a warm amber accent for badges, streaks, and other highlights.
///
/// [light] wires the palette into a full [ThemeData] so every screen picks
/// up consistent colors, typography (Poppins for headings, Nunito for body),
/// rounded cards/buttons/inputs, and a soft mint surface without per-screen
/// styling.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF16A975);
  static const Color secondary = Color(0xFF0E7C66);
  static const Color accent = Color(0xFFFFB74D);

  /// Emerald → teal gradient used for hero/header sections across screens.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [seed, secondary],
  );

  static const double cardRadius = 20;
  static const double fieldRadius = 16;

  /// Shared macro accent colors, used for icons/highlights wherever protein,
  /// carbs, or fat are broken out individually (Home, Food, Dashboard).
  static const Color proteinColor = Color(0xFF0E7C66);
  static const Color carbsColor = Color(0xFFFFB74D);
  static const Color fatColor = Color(0xFFEF6C75);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      secondary: secondary,
      tertiary: accent,
      tertiaryContainer: const Color(0xFFFFE3BC),
      onTertiaryContainer: const Color(0xFF7A4A00),
    );

    final baseTextTheme = ThemeData(brightness: Brightness.light).textTheme;
    final textTheme = GoogleFonts.nunitoTextTheme(baseTextTheme).copyWith(
      displaySmall: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: baseTextTheme.displaySmall?.fontSize,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: baseTextTheme.headlineMedium?.fontSize,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: baseTextTheme.headlineSmall?.fontSize,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: baseTextTheme.titleLarge?.fontSize,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: baseTextTheme.titleMedium?.fontSize,
        color: colorScheme.onSurface,
      ),
    );

    final roundedField = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius)),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: roundedField,
        enabledBorder: roundedField,
        disabledBorder: roundedField,
        focusedBorder: roundedField.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: roundedField.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: roundedField.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? colorScheme.primary : null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary.withValues(alpha: 0.35)
              : null;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius)),
      ),
    );
  }
}
