import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF4F46E5);
  static const Color accent = Color(0xFF06B6D4);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [seed, secondary],
  );

  static const double cardRadius = 14;
  static const double fieldRadius = 12;

  static const Color proteinColor = seed;
  static const Color carbsColor = secondary;
  static const Color fatColor = accent;

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ).copyWith(
          primary: seed,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDBEAFE),
          onPrimaryContainer: const Color(0xFF1E3A8A),
          secondary: secondary,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFE0E7FF),
          onSecondaryContainer: const Color(0xFF312E81),
          tertiary: accent,
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFCFFAFE),
          onTertiaryContainer: const Color(0xFF164E63),
          surface: surface,
          onSurface: ink,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF1F5F9),
          surfaceContainer: const Color(0xFFEFF6FF),
          surfaceContainerHigh: Colors.white,
          surfaceContainerHighest: const Color(0xFFE2E8F0),
          onSurfaceVariant: muted,
          outline: const Color(0xFF94A3B8),
          outlineVariant: const Color(0xFFCBD5E1),
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
        elevation: 1,
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shadowColor: ink.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: roundedField,
        enabledBorder: roundedField.copyWith(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
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
            color: selected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : null;
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
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
      ),
    );
  }
}
