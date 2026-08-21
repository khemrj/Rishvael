import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/api_failure.dart';
import '../models/user_profile.dart';
import '../data/dashboard_repository.dart';
import '../models/feed_models.dart';

/// ===========================================================================
/// 1. DEPENDENCY INJECTION — providers are your service locator, but typed,
///    overridable in tests, and disposed automatically.
/// ===========================================================================

/// Your ApiClient is a static singleton, so DI here is one line. The provider
/// still matters: in a widget test you override it with a fake client and the
/// whole dashboard talks to your fake instead of the network.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

/// ===========================================================================
/// 2. UTILITIES every real app ends up writing
/// ===========================================================================

/// autoDispose is right by default, but "user taps a tab and taps straight
/// back" shouldn't refetch. Keep the cache warm for a window, then let go.
void cacheFor(Ref ref, Duration duration) {
  final link = ref.keepAlive();
  final timer = Timer(duration, link.close);
  ref.onDispose(timer.cancel);
}

/// Ties an HTTP request to the provider's lifetime. Screen closed mid-flight →
/// the socket is actually aborted, not just ignored. On a 3G connection in
/// Kathmandu that is the difference between snappy and molasses.
CancelToken autoCancel(Ref ref) {
  final token = CancelToken();
  ref.onDispose(() => token.cancel('provider disposed'));
  return token;
}

/// ===========================================================================
/// 3. THE PROFILE — AsyncNotifier, because it has both state AND commands.
///    FutureProvider = read-only. AsyncNotifier = read + mutate.
/// ===========================================================================

final profileProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(ProfileController.new);

class ProfileController extends AsyncNotifier<UserProfile> {
  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);
  bool _mounted = true;

  /// `build` runs on first watch and on every `ref.invalidate`.
  /// Throw freely — Riverpod catches it into `AsyncError` for you.
  @override
  Future<UserProfile> build() async {
    _mounted = true;
    ref.onDispose(() => _mounted = false);
    final cancel = autoCancel(ref);
    return _repo.fetchProfile(cancel: cancel);
  }

  /// OPTIMISTIC UPDATE — the pattern that makes an app feel instant.
  /// Paint the new state now, reconcile with the server after, roll back on
  /// failure. Users forgive a rare rollback; they never forgive a 600ms spinner
  /// after toggling a switch.
  Future<void> setOpenToWork(bool value) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(openToWork: value));
    try {
      final saved = await _repo.updateProfile(current.copyWith(openToWork: value));
      if (!_mounted) return; // the notifier may be gone after an await
      state = AsyncData(saved);
    } on ApiFailure {
      if (!_mounted) return;
      state = AsyncData(current); // roll back to exactly what we had
      rethrow;                    // let the UI show a snackbar
    }
  }

  /// PESSIMISTIC UPDATE — for edits where a silent rollback would confuse
  /// (a form the user just filled in). Show the spinner, then commit.
  Future<void> save(UserProfile edited) async {
    // `AsyncValue.guard` = try/catch/finally in one line, and it preserves the
    // previous data so the screen doesn't flash empty while saving.
    state = const AsyncLoading<UserProfile>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _repo.updateProfile(edited));
  }
}

/// DERIVED STATE. Never recompute this in `build()` of five widgets — compute
/// once, cache, and let Riverpod invalidate it when the profile changes.
final profileCompletenessProvider = Provider<double>((ref) {
  // `.select` = "rebuild me only when THIS slice changes."
  // Without select, a change to `profileViews` would recompute completeness.
  return ref.watch(
    profileProvider.select((p) => p.value?.completeness ?? 0),
  );
});

/// ===========================================================================
/// 4. THE DASHBOARD FEED — four INDEPENDENT providers, not one mega-future.
///
///    This is the answer to "how do I fetch multiple things efficiently".
///    Riverpod starts all four the moment their widgets mount, so they run
///    concurrently — you get Future.wait parallelism for free. The difference:
///
///      one mega-future  → advisory endpoint 500s → the ENTIRE dashboard is red
///      four providers   → advisory card shows retry, other three render fine
///
///    Fault isolation and independent refresh, from the graph shape alone.
/// ===========================================================================

final opportunityFilterProvider =
    NotifierProvider<OpportunityFilterController, OpportunityKind?>(
  OpportunityFilterController.new,
);

class OpportunityFilterController extends Notifier<OpportunityKind?> {
  @override
  OpportunityKind? build() => null; // null = "All"

  void select(OpportunityKind? kind) => state = kind;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryController, String>(SearchQueryController.new);

class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String q) => state = q;
}

/// DEBOUNCE, the Riverpod way — no Timer soup in a StatefulWidget.
/// Every keystroke re-runs this provider, which disposes the previous run;
/// the previous run's `ref.mounted` flips false and it bails before the network.
final _debouncedQueryProvider = FutureProvider.autoDispose<String>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return '';

  var isMounted = true;
  ref.onDispose(() => isMounted = false);

  await Future<void>.delayed(const Duration(milliseconds: 350));
  if (!isMounted) throw const CancelledFailure(); // superseded by a newer key
  return query;
});

final opportunitiesProvider =
    FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final kind = ref.watch(opportunityFilterProvider);
  // `.future` awaits the debounce; this provider simply doesn't run until the
  // typing settles. Chaining providers > orchestrating timers.
  final query = await ref.watch(_debouncedQueryProvider.future);

  cacheFor(ref, const Duration(minutes: 2));
  return ref.watch(dashboardRepositoryProvider).fetchOpportunities(
        kind: kind,
        query: query,
        cancel: autoCancel(ref),
      );
});

final applicationsProvider =
    FutureProvider.autoDispose<List<ApplicationRecord>>((ref) async {
  cacheFor(ref, const Duration(minutes: 5));
  return ref
      .watch(dashboardRepositoryProvider)
      .fetchApplications(cancel: autoCancel(ref));
});

final advisoryProvider =
    FutureProvider.autoDispose<List<AdvisorySession>>((ref) async {
  cacheFor(ref, const Duration(minutes: 5));
  return ref
      .watch(dashboardRepositoryProvider)
      .fetchAdvisory(cancel: autoCancel(ref));
});

final suggestionsProvider =
    FutureProvider.autoDispose<List<ConnectionSuggestion>>((ref) async {
  cacheFor(ref, const Duration(minutes: 10));
  return ref
      .watch(dashboardRepositoryProvider)
      .fetchSuggestions(cancel: autoCancel(ref));
});

/// PULL-TO-REFRESH, done correctly.
///
/// `invalidate` marks providers stale (they refetch on next watch).
/// Awaiting `.future` afterwards is what keeps the spinner spinning until the
/// data actually lands — `RefreshIndicator` needs a Future that completes.
///
/// `eagerError: false` (the default) means one failing endpoint doesn't hide
/// the other three; each card renders its own error.
Future<void> refreshDashboard(WidgetRef ref) async {
  ref
    ..invalidate(profileProvider)
    ..invalidate(opportunitiesProvider)
    ..invalidate(applicationsProvider)
    ..invalidate(advisoryProvider)
    ..invalidate(suggestionsProvider);

  // Swallow here only: each card already renders its own error state, and an
  // unhandled rejection inside Future.wait would abort the whole refresh.
  await Future.wait([
    _settle(ref.read(profileProvider.future)),
    _settle(ref.read(opportunitiesProvider.future)),
    _settle(ref.read(applicationsProvider.future)),
    _settle(ref.read(advisoryProvider.future)),
    _settle(ref.read(suggestionsProvider.future)),
  ]);
}

/// `Future.wait` is all-or-nothing: the first rejection completes the whole
/// wait with an error while the rest keep running in the background. Normalising
/// each future to "never throws" is how you get JS's `allSettled` in Dart.
Future<void> _settle(Future<Object?> future) async {
  try {
    await future;
  } catch (_) {
    
  }
}

/// ===========================================================================
/// 5. ONE-OFF ACTIONS (apply to an internship). No provider state — just a
///    typed callback the UI can await and show a snackbar for.
/// ===========================================================================
final applyToOpportunityProvider =
    Provider<Future<void> Function(String id, {String? note})>((ref) {
  return (id, {note}) async {
    await ref.read(dashboardRepositoryProvider).apply(id, note: note);
    // Server is now the source of truth for both lists → refetch both.
    ref
      ..invalidate(opportunitiesProvider)
      ..invalidate(applicationsProvider);
  };
});
