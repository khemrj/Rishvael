import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Application-wide Rishvael theme.
///
/// Responsibilities:
/// - Build Material ColorScheme
/// - Configure typography
/// - Configure common Material components
/// - Connect AppColors to Flutter's theme system
///
/// Page-specific styling should remain inside the page/component.
abstract final class AppTheme {
  // ---------------------------------------------------------------------------
  // PUBLIC THEMES
  // ---------------------------------------------------------------------------

  static ThemeData light() {
    return _buildLightTheme();
  }

  static ThemeData dark() {
    return _buildDarkTheme();
  }

  // ---------------------------------------------------------------------------
  // LIGHT THEME
  // ---------------------------------------------------------------------------

  static ThemeData _buildLightTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,

      // Brand
      primary: AppColors.navy,
      onPrimary: AppColors.ivory,

      secondary: AppColors.gold,
      onSecondary: AppColors.ink,

      tertiary: AppColors.gold,
      onTertiary: AppColors.ink,

      // Surfaces
      surface: AppColors.parchment,
      onSurface: AppColors.ink,

      surfaceContainerHighest: AppColors.white,

      // System
      error: AppColors.error,
      onError: AppColors.onError,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
  }

  // ---------------------------------------------------------------------------
  // DARK THEME
  // ---------------------------------------------------------------------------

  static ThemeData _buildDarkTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,

      // Brand
      primary: AppColors.gold,
      onPrimary: AppColors.navy,

      secondary: AppColors.gold,
      onSecondary: AppColors.navy,

      tertiary: AppColors.gold,
      onTertiary: AppColors.navy,

      // Surfaces
      surface: AppColors.navy,
      onSurface: AppColors.ivory,

      surfaceContainerHighest: AppColors.navyCard,

      // System
      error: AppColors.error,
      onError: AppColors.onError,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );
  }

  // ---------------------------------------------------------------------------
  // COMMON THEME
  // ---------------------------------------------------------------------------

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
  }) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      // -----------------------------------------------------------------------
      // MATERIAL
      // -----------------------------------------------------------------------

      useMaterial3: true,

      colorScheme: colorScheme,

      // All normal text defaults to Montserrat.
      fontFamily: AppColors.bodyFont,

      scaffoldBackgroundColor:
          isLight ? AppColors.parchment : AppColors.navy,

      visualDensity: VisualDensity.adaptivePlatformDensity,

      // -----------------------------------------------------------------------
      // TYPOGRAPHY
      // -----------------------------------------------------------------------

      textTheme: _buildTextTheme(colorScheme),

      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------

      appBarTheme: AppBarTheme(
        centerTitle: false,

        elevation: 0,

        scrolledUnderElevation: 0,

        backgroundColor:
            isLight ? AppColors.parchment : AppColors.navy,

        foregroundColor:
            isLight ? AppColors.ink : AppColors.ivory,

        surfaceTintColor: Colors.transparent,

        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      // -----------------------------------------------------------------------
      // CARDS
      // -----------------------------------------------------------------------

      cardTheme: CardThemeData(
        elevation: 0,

        margin: EdgeInsets.zero,

        clipBehavior: Clip.antiAlias,

        color: isLight
            ? AppColors.white
            : AppColors.navyCard,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),

          side: BorderSide(
            color: isLight
                ? AppColors.slate.withValues(alpha: 0.20)
                : AppColors.gold.withValues(alpha: 0.30),
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // FILLED BUTTON
      // -----------------------------------------------------------------------

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),

          backgroundColor:
              isLight ? AppColors.navy : AppColors.gold,

          foregroundColor:
              isLight ? AppColors.ivory : AppColors.navy,

          shape: const StadiumBorder(),

          textStyle: const TextStyle(
            fontFamily: AppColors.bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // OUTLINED BUTTON
      // -----------------------------------------------------------------------

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),

          foregroundColor:
              isLight ? AppColors.navy : AppColors.gold,

          side: BorderSide(
            color:
                isLight ? AppColors.navy : AppColors.gold,
          ),

          shape: const StadiumBorder(),

          textStyle: const TextStyle(
            fontFamily: AppColors.bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // TEXT BUTTON
      // -----------------------------------------------------------------------

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,

          minimumSize: const Size(48, 48),

          textStyle: const TextStyle(
            fontFamily: AppColors.bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // INPUT FIELDS
      // -----------------------------------------------------------------------

      inputDecorationTheme: _buildInputDecorationTheme(
        isLight: isLight,
      ),

      // -----------------------------------------------------------------------
      // CHIPS
      // -----------------------------------------------------------------------

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),

        side: BorderSide(
          color: isLight
              ? AppColors.slate.withValues(alpha: 0.30)
              : AppColors.gold.withValues(alpha: 0.35),
        ),

        backgroundColor: Colors.transparent,

        labelStyle: TextStyle(
          fontFamily: AppColors.bodyFont,
          fontSize: 12,
          color: isLight
              ? AppColors.ink
              : AppColors.ivory,
        ),
      ),

      // -----------------------------------------------------------------------
      // NAVIGATION BAR
      // -----------------------------------------------------------------------

      navigationBarTheme: NavigationBarThemeData(
        height: 68,

        elevation: 0,

        backgroundColor:
            isLight ? AppColors.white : AppColors.navy,

        indicatorColor:
            AppColors.gold.withValues(alpha: 0.18),

        labelBehavior:
            NavigationDestinationLabelBehavior.onlyShowSelected,

        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: AppColors.bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // NAVIGATION RAIL
      // -----------------------------------------------------------------------

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isLight ? AppColors.white : AppColors.navy,

        indicatorColor:
            AppColors.gold.withValues(alpha: 0.18),

        labelType: NavigationRailLabelType.all,
      ),

      // -----------------------------------------------------------------------
      // DIVIDERS
      // -----------------------------------------------------------------------

      dividerTheme: DividerThemeData(
        color: isLight
            ? AppColors.slate.withValues(alpha: 0.18)
            : AppColors.gold.withValues(alpha: 0.18),

        space: 1,

        thickness: 1,
      ),

      // -----------------------------------------------------------------------
      // ICONS
      // -----------------------------------------------------------------------

      iconTheme: IconThemeData(
        color: isLight
            ? AppColors.ink
            : AppColors.ivory,

        size: 24,
      ),

      // -----------------------------------------------------------------------
      // SPLASH
      // -----------------------------------------------------------------------

      splashFactory: InkSparkle.splashFactory,
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT DECORATION
  // ---------------------------------------------------------------------------

  static InputDecorationTheme _buildInputDecorationTheme({
    required bool isLight,
  }) {
    final borderColor = isLight
        ? AppColors.slate.withValues(alpha: 0.30)
        : AppColors.gold.withValues(alpha: 0.30);

    final focusedBorderColor =
        isLight ? AppColors.navy : AppColors.gold;

    return InputDecorationTheme(
      filled: true,

      fillColor:
          isLight ? AppColors.white : AppColors.navyCard,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: focusedBorderColor,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.error,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),

      labelStyle: TextStyle(
        fontFamily: AppColors.bodyFont,
        color: isLight
            ? AppColors.slate
            : AppColors.ivoryMuted,
      ),

      hintStyle: TextStyle(
        fontFamily: AppColors.bodyFont,
        color: isLight
            ? AppColors.slate
            : AppColors.ivoryMuted,
      ),

      errorStyle: const TextStyle(
        fontFamily: AppColors.bodyFont,
        fontSize: 11,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TYPOGRAPHY
  // ---------------------------------------------------------------------------

  static TextTheme _buildTextTheme(
    ColorScheme colorScheme,
  ) {
    const displayFont = AppColors.displayFont;
    const bodyFont = AppColors.bodyFont;

    return TextTheme(
      // -----------------------------------------------------------------------
      // DISPLAY
      // -----------------------------------------------------------------------

      displayLarge: const TextStyle(
        fontFamily: displayFont,
        fontSize: 48,
        fontWeight: FontWeight.w600,
        height: 1.05,
      ),

      displayMedium: const TextStyle(
        fontFamily: displayFont,
        fontSize: 42,
        fontWeight: FontWeight.w600,
        height: 1.05,
      ),

      displaySmall: const TextStyle(
        fontFamily: displayFont,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.08,
      ),

      // -----------------------------------------------------------------------
      // HEADLINES
      // -----------------------------------------------------------------------

      headlineLarge: const TextStyle(
        fontFamily: displayFont,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.10,
      ),

      headlineMedium: const TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.10,
      ),

      headlineSmall: const TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),

      // -----------------------------------------------------------------------
      // TITLES
      // -----------------------------------------------------------------------

      titleLarge: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),

      titleMedium: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),

      titleSmall: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------

      bodyLarge: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 15,
        height: 1.5,
      ),

      bodyMedium: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        height: 1.5,
      ),

      bodySmall: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        height: 1.45,
      ),

      // -----------------------------------------------------------------------
      // LABELS
      // -----------------------------------------------------------------------

      labelLarge: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),

      labelMedium: const TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),

      /// Small uppercase "eyebrow" text.
      labelSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}