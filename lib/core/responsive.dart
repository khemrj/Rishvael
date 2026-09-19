import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// RESPONSIVE  ≠  ADAPTIVE. Learn the difference once and never write
/// `if (Platform.isIOS) width = 320` again.
///
///   RESPONSIVE = reacts to SIZE.      Phone rotates → rail replaces bottom bar.
///   ADAPTIVE   = reacts to PLATFORM.  iOS gets a sliding switch + back-swipe.
///
/// A tablet in portrait and a small desktop window are the SAME layout
/// problem. Never branch on `Platform.isAndroid` to pick a layout — a folded
/// Galaxy Z is Android at 380px wide and Android at 1100px wide, in the same
/// second.
///
/// SEPARATION OF CONCERN — what lives where:
///   responsive.dart   → SIZE and PLATFORM queries only. No colors, no
///                        TextStyle, no widget content. If you're tempted to
///                        put a Color or a copy string in this file, it
///                        belongs in app_colors.dart / app_theme.dart instead.
///   app_colors.dart   → raw Color values (Brand.navy, Brand.gold).
///   app_theme.dart    → composes ThemeData FROM app_colors — the only file
///                        that constructs a ThemeData object.
///   widgets/adaptive_page.dart, adaptive_list_page.dart → page SHELLS that
///                        consume this file's breakpoints; they don't define
///                        their own.
/// ---------------------------------------------------------------------------

/// Material 3 window size classes — the real numbers Google specifies.
/// Don't invent your own 768/1024 from the Bootstrap era.
enum WindowSize {
  compact, // < 600    phones portrait
  medium, // 600–839   phones landscape, small tablets, folded
  expanded, // 840–1199  tablets, small desktop windows
  large, // 1200–1599 desktop
  extraLarge; // >= 1600  ultrawide

  static WindowSize fromWidth(double width) => switch (width) {
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
  /// THE most common Flutter performance bug: `.of()` subscribes to the
  /// WHOLE MediaQueryData, so the widget rebuilds when the keyboard opens,
  /// when the user changes text scale, when notch padding shifts. `.sizeOf()`
  /// subscribes to size only. Same discipline applies to `.paddingOf` and
  /// `.viewInsetsOf` below — always reach for these, never `.of(context)`.
  Size get windowSize => MediaQuery.sizeOf(this);

  WindowSize get breakpoint => WindowSize.fromWidth(windowSize.width);

  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Safe-area insets (notches, status bar) without subscribing to the
  /// rest of MediaQueryData. Reach for this instead of
  /// `MediaQuery.of(context).padding` when a generic component (a sticky
  /// bottom action bar, say) needs to sit above the system nav bar.
  EdgeInsets get safeInsets => MediaQuery.paddingOf(this);

  /// Height currently covered by the on-screen keyboard. Useful for a
  /// generic bottom-sheet form that needs to lift its content above the
  /// keyboard without rebuilding on unrelated MediaQuery changes.
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;

  /// True when the pointer is precise (mouse/trackpad) → show hover states,
  /// tighter hit targets, right-click menus. False on touch → keep the
  /// Material minimum 48dp tap target.
  bool get hasPreciseInput => switch (Theme.of(this).platform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux =>
          true,
        _ => kIsWeb, // web could be either; assume precise, still keep 48dp.
      };

  /// Apple-flavoured chrome. `Theme.of(context).platform` (not
  /// `Platform.isIOS`) so widget tests and
  /// `debugDefaultTargetPlatformOverride` work correctly.
  bool get isApple => switch (Theme.of(this).platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => true,
        _ => false,
      };

  /// Users who set 200% font size are roughly 7% of real-world traffic.
  /// Cap the damage on dense data rows (a stat card, a table row) without
  /// ignoring accessibility entirely.
  TextScaler clampedTextScaler({double max = 1.6}) =>
      MediaQuery.textScalerOf(this).clamp(maxScaleFactor: max);
}

/// Pick a value per breakpoint without a wall of if/else. Falls DOWN to the
/// nearest smaller definition, so you only specify what actually changes.
///
///   final cols = const Responsive(compact: 1, expanded: 2, large: 3)
///       .of(context);
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

/// Design tokens for SPACING only. Numbers live here, never inline in a
/// widget file. Colors live in app_colors.dart, never here — keep the two
/// token systems separate so a designer changing the palette never has to
/// open a file named "responsive".
abstract final class Insets {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;

  /// Gutters grow with the window — a 16px margin on a 27" monitor looks
  /// broken. Stepped per breakpoint (matches the rest of the app's
  /// step-based sizing, e.g. NavigationRail vs Drawer).
  static const page = Responsive<double>(compact: 16, expanded: 24, large: 32);

  /// Alternative to [page]: smoothly interpolated padding instead of a hard
  /// jump at a breakpoint boundary. Prefer [page] for consistency across
  /// most screens; reach for this only on a page where a visible "snap" in
  /// padding while resizing a desktop/web window would look janky (e.g. a
  /// live-resizable split view). Same underlying MediaQuery.sizeOf reads —
  /// no extra rebuild cost over [page].
  static double smooth(BuildContext context) {
    final width = context.windowSize.width;
    if (width < 360) return 16;
    if (width < 600) return 24;
    if (width < 1024) return 64;
    return (width - 1024) / 2 + 64;
  }
}

abstract final class Radii {
  static const card = BorderRadius.all(Radius.circular(16));
  static const chip = BorderRadius.all(Radius.circular(999));
}

/// Text is unreadable past roughly 75 characters per line. On a 1920px
/// monitor an unconstrained Column of paragraphs is a wall. Clamp it and
/// centre it. Every page's top-level content should be wrapped in this
/// (see AdaptivePage / AdaptiveListPage, which already do it for you).
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

/// LayoutBuilder vs MediaQuery — the rule to defend in code review:
///
///   MediaQuery    = "how big is the WINDOW?" → picks the nav pattern
///                    (shell level: dashboard picks rail vs bottom bar).
///   LayoutBuilder = "how big is MY SLOT?"    → picks a component's
///                    internal layout (a card inside a fixed-width panel).
///
/// A card inside a 320px rail-adjacent panel is compact even on a 1600px
/// screen. If that card reads MediaQuery instead, it renders desktop-wide
/// and overflows its slot. Use this for any generic, reusable component
/// (a stat card, a form section) that might be embedded in different slot
/// widths across different pages.
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

/// Web and desktop don't drag-scroll by default, which feels broken to
/// anyone testing a web build on a touchscreen laptop. Install once on
/// MaterialApp.scrollBehavior — never per-page.
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
/// ADAPTIVE HELPERS — platform-flavoured chrome, not size-based layout.
/// Flutter ships `.adaptive` constructors — reach for those FIRST before
/// hand-rolling: Switch.adaptive, Slider.adaptive,
/// CircularProgressIndicator.adaptive, showAdaptiveDialog, AlertDialog.adaptive,
/// Icons.adaptive.share. [Adaptive.confirm] below is the one case (a
/// confirm/cancel action sheet) that's common enough across the app to be
/// worth a single named helper instead of rebuilding the dialog per call site.
/// ---------------------------------------------------------------------------
abstract final class Adaptive {
  /// iOS users expect a bottom-anchored action sheet with destructive-red
  /// styling; Android expects a Material dialog. Same call site either way —
  /// this is the generic confirm dialog every "Delete", "Sign out", "Discard
  /// changes" flow in the app should route through, so that behavior stays
  /// consistent without each page re-implementing it.
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
                    foregroundColor: Theme.of(ctx).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}