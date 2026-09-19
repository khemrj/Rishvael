import 'package:flutter/material.dart';

/// Rishvael brand color tokens.
///
/// Keep all brand colors here.
/// Do not create Color(...) values inside individual pages.
///
/// Brand philosophy:
/// - Navy  → authority, trust, professionalism
/// - Gold  → premium accent, verification, important actions
/// - Ivory → primary text on dark surfaces
/// - Parchment → light application background
/// - Slate → secondary/muted text
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // BRAND
  // ---------------------------------------------------------------------------

  /// Primary Rishvael navy.
  static const Color navy = Color(0xFF0D1B3E);
  static const Color goldDark =  Color.fromRGBO(154, 123, 44, 1);

  /// Slightly lighter navy used for cards and elevated dark surfaces.
  static const Color navyCard = Color(0xFF142653);

  /// Rishvael signature gold.
  static const Color gold = Color(0xFFC9A84C);

  // ---------------------------------------------------------------------------
  // LIGHT SURFACE COLORS
  // ---------------------------------------------------------------------------

  /// Main light-mode application background.
  static const Color parchment = Color(0xFFF7F5F0);

  /// Primary dark text on light backgrounds.
  static const Color ink = Color(0xFF12151C);

  /// Secondary text on light backgrounds.
  static const Color slate = Color(0xFF5A6478);

  /// White surface.
  static const Color white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // DARK SURFACE COLORS
  // ---------------------------------------------------------------------------

  /// Primary text on dark backgrounds.
  static const Color ivory = Color(0xFFF8F6EF);

  /// Secondary text on dark backgrounds.
  static const Color ivoryMuted = Color(0xFFB9BECC);

  // ---------------------------------------------------------------------------
  // SYSTEM / SEMANTIC COLORS
  // ---------------------------------------------------------------------------

  static const Color error = Color(0xFFBA1A1A);

  static const Color onError = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF3F6B45);

  static const Color warning = Color(0xFF8A6914);

  // ---------------------------------------------------------------------------
  // BRAND TYPOGRAPHY
  // ---------------------------------------------------------------------------

  /// Serif display font.
  ///
  /// Used for:
  /// - Page headings
  /// - Major titles
  /// - Brand/editorial content
  static const String displayFont = 'CormorantGaramond';

  /// Sans-serif body font.
  ///
  /// Used for:
  /// - Body text
  /// - Buttons
  /// - Forms
  /// - Labels
  static const String bodyFont = 'Montserrat';
}