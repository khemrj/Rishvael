import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_failure.dart';

/// One place that decides what loading/error looks like. Write this once and
/// every screen in the app is consistent for free.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.skeleton,
    this.compactError = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final Widget? skeleton;
  final bool compactError;

  @override
  Widget build(BuildContext context) {
    // Riverpod 3 made AsyncValue `sealed`, so `switch` is exhaustive.
    //
    // The ORDER matters and this order is deliberate:
    //   `AsyncValue(:final value?)` matches whenever we hold data — including
    //   while a refresh is in flight. That means pull-to-refresh keeps the old
    //   list on screen instead of flashing a spinner. Put AsyncLoading first
    //   and you get the flicker every Riverpod beginner ships.
    return switch (value) {
      AsyncValue(value: final loaded?) => data(loaded),
      AsyncValue(error: final failure?) => _ErrorState(
          failure: ApiFailure.from(failure),
          onRetry: onRetry,
          compact: compactError,
        ),
      _ => skeleton ?? const _Skeleton(),
    };
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.failure,
    required this.onRetry,
    this.compact = false,
  });

  final ApiFailure failure;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Copy rule: say what happened and what to do. Never "Oops!", never a
    // stack trace, never an apology. Errors give direction, not mood.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            switch (failure) {
              NetworkFailure() => Icons.wifi_off_rounded,
              ForbiddenFailure() => Icons.lock_outline_rounded,
              NotFoundFailure() => Icons.search_off_rounded,
              _ => Icons.error_outline_rounded,
            },
            color: theme.colorScheme.onSurfaceVariant,
            size: compact ? 20 : 28,
          ),
          const SizedBox(height: 8),
          Text(failure.message, style: theme.textTheme.bodyMedium),
          if (failure.isRetryable) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeletons beat spinners: they reserve the final layout, so nothing jumps
/// when data lands. Perceived speed is layout stability, not milliseconds.
class _Skeleton extends StatefulWidget {
  const _Skeleton();

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  // `vsync: this` ties the ticker to this widget's visibility — off-screen,
  // it stops burning frames. An AnimationController without vsync is a
  // background CPU leak.
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose(); // Forget this and you leak a ticker per rebuild.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FadeTransition(
        // Never animate opacity below ~0.25: it reads as a flicker, and it
        // trips motion-sensitivity. Respect MediaQuery.disableAnimationsOf too.
        opacity: Tween(begin: 0.35, end: 0.75).animate(_c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final w in const [0.5, 0.85, 0.7])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: w,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: base.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
