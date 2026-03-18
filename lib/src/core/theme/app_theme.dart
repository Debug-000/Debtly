import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/tokens.dart';
import '../../domain/models/models.dart';

class AppTheme {
  static ThemeData dark([AccentTheme accentTheme = AccentTheme.ocean]) {
    final accent = AppAccentColors.fromTheme(accentTheme);
    final scheme = const ColorScheme.dark(
      primary: Color(0xFF6AA6FF),
      secondary: AppPalette.info,
      surface: AppPalette.surface,
      error: AppPalette.danger,
      onPrimary: Color(0xFF1B1715),
      onSecondary: AppPalette.textPrimary,
      onSurface: AppPalette.textPrimary,
      onError: AppPalette.textPrimary,
    ).copyWith(primary: accent.primary, secondary: accent.soft);

    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      Typography.whiteMountainView,
    );

    final textTheme = baseText.copyWith(
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppPalette.textPrimary,
        letterSpacing: -1.1,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppPalette.textPrimary,
        letterSpacing: -0.8,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppPalette.textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppPalette.textPrimary,
        letterSpacing: -0.3,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppPalette.textPrimary,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppPalette.textSecondary,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        color: AppPalette.textPrimary,
        height: 1.45,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        color: AppPalette.textSecondary,
        height: 1.4,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        color: AppPalette.textMuted,
        height: 1.35,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppPalette.textPrimary,
      ),
      labelMedium: baseText.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppPalette.textSecondary,
      ),
    );

    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: accent.primary.withValues(alpha: 0.10)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      extensions: [accent],
      scaffoldBackgroundColor: AppPalette.background,
      canvasColor: AppPalette.background,
      cardColor: AppPalette.surface,
      dividerColor: AppPalette.border,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.background.withValues(alpha: 0.94),
        foregroundColor: AppPalette.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontSize: 22),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: accent.primary.withValues(alpha: 0.12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.surfaceRaised,
        selectedColor: accent.primary.withValues(alpha: 0.18),
        secondarySelectedColor: accent.primary.withValues(alpha: 0.18),
        disabledColor: AppPalette.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: accent.primary.withValues(alpha: 0.12)),
        ),
        side: BorderSide(color: accent.primary.withValues(alpha: 0.12)),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppPalette.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        brightness: Brightness.dark,
        pressElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.backgroundSoft,
        indicatorColor: AppPalette.surfaceRaised,
        height: 78,
        shadowColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? accent.primary
                : AppPalette.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppPalette.textPrimary
                : AppPalette.textMuted,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppPalette.textMuted),
        labelStyle: textTheme.bodyMedium,
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: accent.primary, width: 1.2),
        ),
        errorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppPalette.danger),
        ),
        focusedErrorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppPalette.danger, width: 1.2),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? accent.primary.withValues(alpha: 0.18)
                : AppPalette.surfaceRaised,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppPalette.textPrimary
                : AppPalette.textSecondary,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => accent.primary.withValues(
              alpha: states.contains(WidgetState.pressed) ? 0.16 : 0.08,
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: accent.primary.withValues(alpha: 0.12)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent.primary,
          foregroundColor: const Color(0xFF181412),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          elevation: 0,
          overlayColor: accent.deep.withValues(alpha: 0.22),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.textPrimary,
          side: BorderSide(color: accent.primary.withValues(alpha: 0.14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          overlayColor: accent.primary.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent.primary,
          overlayColor: accent.primary.withValues(alpha: 0.12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.primary
              : AppPalette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.primary.withValues(alpha: 0.28)
              : AppPalette.surfaceMuted,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppPalette.textSecondary,
        textColor: AppPalette.textPrimary,
        contentPadding: EdgeInsets.zero,
        selectedColor: accent.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent.primary,
        linearTrackColor: AppPalette.surfaceMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppPalette.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: accent.primary.withValues(alpha: 0.08),
      hoverColor: accent.primary.withValues(alpha: 0.06),
    );
  }

  static ThemeData light([AccentTheme accentTheme = AccentTheme.ocean]) =>
      dark(accentTheme);
}
