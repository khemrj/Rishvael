import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/pages/Chat/conversation_screen.dart';
import 'package:flutter_application_1/pages/people_page.dart';
import 'package:flutter_application_1/pages/user_search_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/AuthNotifier.dart';
import 'login_page.dart';

import '../core/responsive.dart';
import '../core/theme/app_theme.dart';
import '../models/opportunity_model.dart';
import 'profile/profile_page.dart';
import 'profile/widgets/member_avatar.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard/advisory_page.dart';
import 'dashboard/chat_screen.dart';
import 'dashboard/network_page.dart';
import 'dashboard/opportunities_page.dart';
import '../pages/post_opportunity_page.dart';

/// A record type (Dart 3): a tuple with named fields, no class boilerplate.8
/// Perfect for config lists that never leave this file.
typedef _Dest = ({String label, IconData icon, IconData selectedIcon});

const _destinations = <_Dest>[
  (
    label: 'Opportunities',
    icon: Icons.work_outline_rounded,
    selectedIcon: Icons.work_rounded,
  ),
  (
    label: 'Advisory',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum_rounded,
  ),
  (
    label: 'Network',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
  ),
  (
    label: 'People',
    icon: Icons.person_search_outlined,
    selectedIcon: Icons.person_search_rounded,
  ),
  (
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
];

/// Same class name your login_page already pushes — no routing changes needed.
class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  int _index = 0;

  /// Your original logout, kept verbatim in spirit: clear the token, then wipe
  /// the navigation stack so back can't return to an authenticated screen.
  Future<void> _signOut() async {
    final navigator = Navigator.of(
      context,
      rootNavigator: true,
    ); // capture BEFORE the await
    await ref.read(authProvider.notifier).logout();
    // Drop every cached provider so the next user never sees this one's data.
    ref.invalidate(profileProvider);
    if (!mounted) return;
    await navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<bool> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    return confirm ?? false;
  }

  Future<void> _handleLogoutSequence() async {
    final shouldLogout = await _showLogoutDialog();
    if (!shouldLogout || !mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;

    await navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _go(int i) {
    if (i != _index) setState(() => _index = i);
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const ConversationsScreen(), // Replace with your actual notifications page
      ),
    );
  }

  /// DEV-ONLY: opens the business "post an opportunity" form from the
  /// customer dashboard so you can smoke-test the POST /opportunities
  /// endpoint from your phone without switching accounts. Gated on
  /// kDebugMode — this is stripped from release builds automatically and
  /// will never show up for a real customer.
  Future<void> _openPostOpportunityDebugTool() async {
    final result = await Navigator.of(context).push<Opportunity>(
      MaterialPageRoute(builder: (_) => const PostOpportunityPage()),
    );
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backend confirmed: "${result.title}" (id: ${result.id}) created.',
          ),
        ),
      );
    }
    // No snackbar on a null/cancelled result — PostOpportunityPage already
    // surfaces its own errors inline, so there's nothing new to say here.
  }

  Widget? _buildDebugFab() {
    if (!kDebugMode) return null;
    return FloatingActionButton.extended(
      heroTag: 'debug_post_opportunity_fab',
      onPressed: _openPostOpportunityDebugTool,
      icon: const Icon(Icons.bug_report_outlined),
      label: const Text('Test POST'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = context.breakpoint;

    // ONE decision, made once, at the shell. Every page below is
    // breakpoint-agnostic — it just fills the space it's given.
    final body = _ShellBody(index: _index);

    // Wrap the entire layout in PopScope to intercept the back gesture
    return PopScope(
      canPop:
          false, // Prevents default back gesture or physical button behavior
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // Triggers the async logout sequence when back swipe/button is used
        await _handleLogoutSequence();
      },
      child: switch (size) {
        WindowSize.compact => Scaffold(
          appBar: _buildAppBar(context, showTitle: true),
          body: SafeArea(child: body),
          floatingActionButton: _buildDebugFab(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ),
        WindowSize.medium || WindowSize.expanded => Scaffold(
          appBar: _buildAppBar(context, showTitle: true),
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _go,
                  extended: size.atLeastExpanded,
                  labelType: size.atLeastExpanded
                      ? null
                      : NavigationRailLabelType.selected,
                  leading: const SizedBox(height: 8),
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          ),
          floatingActionButton: _buildDebugFab(),
        ),
        _ => Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                _PermanentDrawer(index: _index, onSelect: _go),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopHeader(
                        title: _destinations[_index].label,
                        onSignOut:
                            _signOut, // Alternatively hook this into the same dialog
                        onOpenProfile: () => _go(4),
                        onOpenNotifications: _openNotifications,
                      ),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildDebugFab(),
        ),
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return AppBar(
      titleSpacing: 20,
      title: showTitle
          ? Text(
              _index == 0 ? 'RISHVAEL' : _destinations[_index].label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: _index == 0 ? 2.0 : 0,
              ),
            )
          : null,
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: _openNotifications,
          icon: const Badge(
            label: Text('3'),
            child: Icon(Icons.notifications_none_rounded),
          ),
        ),
        AccountMenuButton(onOpenProfile: () => _go(4), onSignOut: _signOut),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Keeps every tab's scroll position and state alive, WITHOUT keeping their
/// providers hot.
///
/// Plain IndexedStack keeps hidden pages fully alive — their animations tick
/// and their providers keep polling. Wrapping each child in `TickerMode` is
/// what Riverpod 3 reads to auto-pause listeners of invisible widgets. Result:
/// instant tab switching, zero background network.
class _ShellBody extends StatelessWidget {
  const _ShellBody({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const pages = [
      OpportunitiesPage(),
      PeoplePage(),
      NetworkPage(),
      UserSearchScreen(),
    ];

    return IndexedStack(
      index: index,
      children: [
        for (var i = 0; i < pages.length; i++)
          TickerMode(enabled: i == index, child: pages[i]),
      ],
    );
  }
}

class _PermanentDrawer extends ConsumerWidget {
  const _PermanentDrawer({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider.select((p) => p.value));

    return SizedBox(
      width: 264,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: Radii.chip,
                  ),
                  child: const Text(
                    'R',
                    style: TextStyle(
                      color: AppColors.gold,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'RISHVAEL',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(letterSpacing: 2.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: NavigationDrawer(
              selectedIndex: index,
              onDestinationSelected: onSelect,
              backgroundColor: Colors.transparent,
              children: [
                for (final d in _destinations)
                  NavigationDrawerDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          if (profile != null && profile.completeness < 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _CompletionNudge(
                value: profile.completeness,
                message: profile.nextStep,
                onTap: () => onSelect(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletionNudge extends StatelessWidget {
  const _CompletionNudge({
    required this.value,
    required this.message,
    required this.onTap,
  });

  final double value;
  final String? message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: AppColors.gold.withValues(alpha: 0.10),
      borderRadius: Radii.card,
      child: InkWell(
        borderRadius: Radii.card,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROFILE ${(value * 100).round()}% COMPLETE',
                style: t.labelSmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  color: AppColors.gold,
                  backgroundColor: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!, style: t.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.title,
    required this.onSignOut,
    required this.onOpenProfile,
    required this.onOpenNotifications,
  });

  final String title;
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        children: [
          // Flexible title: truncates instead of pushing the row wider.
          Flexible(
            flex: 0,
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(width: 16),
          // Search takes all remaining space, with a sensible cap.
       
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _GlobalSearchField(),
            ),
          
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Notifications',
            onPressed: onOpenNotifications,
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 8),
          AccountMenuButton(onOpenProfile: onOpenProfile, onSignOut: onSignOut),
        ],
      ),
    );
  }
}

class _GlobalSearchField extends ConsumerWidget {
  const _GlobalSearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      // Debouncing lives in the provider graph, not here. The widget's only
      // job is to report keystrokes.
      onChanged: ref.read(searchQueryProvider.notifier).update,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Search people, firms, roles',
        prefixIcon: Icon(Icons.search_rounded, size: 20),
      ),
    );
  }
}
