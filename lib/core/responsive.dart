import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// RESPONSIVE  ≠  ADAPTIVE. Learn the difference once and you'll never
/// write `if (Platform.isIOS) width = 320` again.
///
///   RESPONSIVE = reacts to SIZE.      Phone rotates → rail replaces bottom bar.
///   ADAPTIVE   = reacts to PLATFORM.  iOS gets a sliding switch + back-swipe.
///
/// A tablet in portrait and a small desktop window are the SAME layout problem.
/// Never branch on `Platform.isAndroid` to pick a layout: a folded Galaxy Z is
/// Android at 380px wide and Android at 1100px wide, in the same second.
/// ---------------------------------------------------------------------------

/// Material 3 window size classes. These are the real numbers Google uses;
/// don't invent your own 768/1024 from the Bootstrap era.
enum WindowSize {
  compact,    // < 600   phones portrait
  medium,     // 600–839 phones landscape, small tablets, folded
  expanded,   // 840–1199 tablets, small desktop windows
  large,      // 1200–1599 desktop
  extraLarge; // >= 1600 ultrawide

  static WindowSize fromWidth(double w) => switch (w) {
        < 600 => WindowSize.compact,
        < 840 => WindowSize.medium,
        < 1200 => WindowSize.expanded,
        < 1600 => WindowSize.large,
        _ => WindowSize.extraLarge,
      };

  bool get isCompact => this == WindowSize.compact;
  bool get atLeastMedium => index >= WindowSize.medium.index;
  bool get atLeastExpanded => index >= WindowSize.expanded.index;
  bool get atLeastLarge => index >= WindowSize.large.index;
}

extension ResponsiveContext on BuildContext {
  /// `MediaQuery.sizeOf(this)` — NOT `MediaQuery.of(this).size`.
  ///
  /// THE most common Flutter performance bug: `.of()` subscribes you to the
  /// WHOLE MediaQueryData, so your widget rebuilds when the keyboard opens,
  /// when the user changes text scale, when the notch padding shifts.
  /// `.sizeOf()` subscribes to size only. Same for `.paddingOf`, `.viewInsetsOf`.
  Size get windowSize => MediaQuery.sizeOf(this);

  WindowSize get breakpoint => WindowSize.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;

  /// True when the pointer is precise (mouse/trackpad) → show hover states,
  /// tighter hit targets, right-click menus. False on touch → 48dp minimum.
  bool get hasPreciseInput =>
      switch (Theme.of(this).platform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux =>
          true,
        _ => kIsWeb, // web could be either; assume precise, still keep 48dp.
      };

  /// Apple-flavoured chrome. `Theme.of(context).platform` (not `Platform.isIOS`)
  /// so widget tests and `debugDefaultTargetPlatformOverride` work.
  bool get isApple => switch (Theme.of(this).platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => true,
        _ => false,
      };

  /// Users who set 200% font size are ~7% of your traffic. Cap the damage on
  /// dense data rows without ignoring them entirely.
  TextScaler clampedTextScaler({double max = 1.6}) =>
      MediaQuery.textScalerOf(this).clamp(maxScaleFactor: max);
}

/// Pick a value per breakpoint without a wall of if/else.
/// Falls DOWN to the nearest smaller definition, so you only specify what changes.
///
///   final cols = const Responsive(compact: 1, expanded: 2, large: 3).of(context);
@immutable
class Responsive<T> {
  const Responsive({
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
    this.extraLarge,
  });

  final T compact;
  final T? medium, expanded, large, extraLarge;

  T resolve(WindowSize size) => switch (size) {
        WindowSize.compact => compact,
        WindowSize.medium => medium ?? compact,
        WindowSize.expanded => expanded ?? medium ?? compact,
        WindowSize.large => large ?? expanded ?? medium ?? compact,
        WindowSize.extraLarge =>
          extraLarge ?? large ?? expanded ?? medium ?? compact,
      };

  T of(BuildContext context) => resolve(context.breakpoint);
}

/// Design tokens. Numbers live HERE, never inline in a widget file.
abstract final class Insets {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;

  /// Gutters grow with the window — a 16px margin on a 27" monitor looks broken.
  static const page = Responsive<double>(compact: 16, expanded: 24, large: 32);
}

abstract final class Radii {
  static const card = BorderRadius.all(Radius.circular(16));
  static const chip = BorderRadius.all(Radius.circular(999));
}

/// Text is unreadable past ~75 characters per line. On a 1920px monitor an
/// unconstrained Column of paragraphs is a wall. Clamp it and centre it.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = 1180});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Insets.page.of(context)),
            child: child,
          ),
        ),
      );
}

/// LayoutBuilder vs MediaQuery — the rule I'd defend in code review:
///
///   MediaQuery = "how big is the WINDOW?"  → picks the nav pattern (shell level)
///   LayoutBuilder = "how big is MY SLOT?"  → picks the card's internal layout
///
/// A card inside a 320px rail-adjacent panel is compact even on a 1600px screen.
/// If you MediaQuery inside that card, it renders desktop-wide and overflows.
class SlotBuilder extends StatelessWidget {
  const SlotBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, WindowSize slot) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => builder(
          context,
          WindowSize.fromWidth(
            c.hasBoundedWidth ? c.maxWidth : context.windowSize.width,
          ),
        ),
      );
}

/// Web + desktop don't drag-scroll by default, which feels broken to anyone
/// testing your web build on a touchscreen laptop. Install once in MaterialApp.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// ---------------------------------------------------------------------------
/// ADAPTIVE HELPERS
/// Flutter ships `.adaptive` constructors — use them before you hand-roll.
///   Switch.adaptive, Slider.adaptive, CircularProgressIndicator.adaptive,
///   showAdaptiveDialog, AlertDialog.adaptive, Icons.adaptive.share
/// ---------------------------------------------------------------------------
abstract final class Adaptive {
  /// iOS users expect destructive-red, bottom-anchored action sheets.
  /// Android expects a Material dialog. Same call site, right muscle memory.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool destructive = false,
  }) async {
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(ctx).colorScheme.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
