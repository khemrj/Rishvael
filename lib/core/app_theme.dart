import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// RISHVAEL brand kit → Flutter tokens.
/// Navy = authority, Gold = the founding-circle accent. Gold is used with
/// restraint: verification, membership tier, one CTA per screen. If gold is
/// everywhere, gold means nothing.
abstract final class Brand {
  static const navy = Color(0xFF0D1B3E);
  static const gold = Color(0xFFC9A84C);
  static const ink = Color(0xFF12151C);
  static const parchment = Color(0xFFF7F5F0);
  static const slate = Color(0xFF5A6478);

  /// Display face for headings only — a serif at 12sp is unreadable.
  static const display = 'CormorantGaramond';
  static const body = 'Montserrat';
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // fromSeed generates 40+ tonally-correct roles (container, onSurfaceVariant,
    // outlineVariant…). Hand-picking those is a week of work you don't need.
    // Override only what the brand actually pins down.
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.navy,
      brightness: brightness,
      primary: brightness == Brightness.light ? Brand.navy : const Color(0xFF9FB2E0),
      secondary: Brand.gold,
      tertiary: Brand.gold,
    );

    final isLight = brightness == Brightness.light;

    return ThemeData(
      // Never `useMaterial3: false` on a new app — you'd be opting into 2018.
      colorScheme: scheme,
      fontFamily: Brand.body,
      scaffoldBackgroundColor: isLight ? Brand.parchment : scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity, // tighter on desktop
      splashFactory: InkSparkle.splashFactory,

      textTheme: _textTheme(scheme),

      appBarTheme: AppBarTheme(
        centerTitle: false, // left-aligned reads as "product", centred as "form"
        scrolledUnderElevation: 0.5,
        backgroundColor: isLight ? Brand.parchment : scheme.surface,
        surfaceTintColor: Colors.transparent,
        // Status-bar icons must contrast the bar, or they vanish on Android.
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias, // stops child images bleeding past radius
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // 48dp = the smallest target a thumb reliably hits. Not negotiable.
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: Brand.body,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: Colors.transparent,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: isLight ? Colors.white : scheme.surface,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: Brand.gold.withValues(alpha: 0.20),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isLight ? Colors.white : scheme.surface,
        indicatorColor: Brand.gold.withValues(alpha: 0.20),
        labelType: NavigationRailLabelType.all,
      ),

      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    // One rule: display/headline = serif, everything else = sans.
    // Serif carries the institution; sans carries the data.
    const serif = TextStyle(fontFamily: Brand.display, height: 1.1);
    return TextTheme(
      displaySmall: serif.copyWith(fontSize: 36, fontWeight: FontWeight.w600),
      headlineLarge: serif.copyWith(fontSize: 30, fontWeight: FontWeight.w600),
      headlineMedium: serif.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      headlineSmall: serif.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(
          fontFamily: Brand.body, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(
          fontFamily: Brand.body, fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontFamily: Brand.body, fontSize: 15, height: 1.5),
      bodyMedium: const TextStyle(fontFamily: Brand.body, fontSize: 14, height: 1.5),
      labelLarge: const TextStyle(
          fontFamily: Brand.body, fontSize: 13, fontWeight: FontWeight.w600),
      // Eyebrows: "MEMBER II · PROFESSIONAL". Tracking-out is the brand tell.
      labelSmall: TextStyle(
        fontFamily: Brand.body,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
