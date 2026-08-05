// lib/pages/admin_dashboard.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import 'login_page.dart';

// ══════════════════════════════════════════════════════════════
//  MODEL
// ══════════════════════════════════════════════════════════════

class AdminUser {
  final int id;
  final String email;
  final String role; // ROLE_ADMIN | ROLE_CUSTOMER
  final bool active;
  final bool locked;
  final int failedAttempts;
  final String? lastLoginAt;
  final String? createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.active,
    required this.locked,
    required this.failedAttempts,
    this.lastLoginAt,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as int,
        email: (j['email'] ?? '') as String,
        role: (j['role'] ?? 'ROLE_CUSTOMER') as String,
        active: (j['active'] ?? true) as bool,
        locked: (j['locked'] ?? false) as bool,
        failedAttempts: (j['failedAttempts'] ?? 0) as int,
        lastLoginAt: j['lastLoginAt'] as String?,
        createdAt: j['createdAt'] as String?,
      );

  AdminUser copyWith({String? role, bool? active, bool? locked}) => AdminUser(
        id: id,
        email: email,
        role: role ?? this.role,
        active: active ?? this.active,
        locked: locked ?? this.locked,
        failedAttempts: failedAttempts,
        lastLoginAt: lastLoginAt,
        createdAt: createdAt,
      );

  bool get isAdmin => role == 'ROLE_ADMIN';
}

// ══════════════════════════════════════════════════════════════
//  SERVICE (API calls via your shared Dio client)
// ══════════════════════════════════════════════════════════════

class _AdminService {
  Future<({List<AdminUser> users, bool last})> fetchUsers({
    required int page,
    int size = 20,
    String sortBy = 'id',
    bool ascending = true,
  }) async {
    final res = await ApiClient.dio.get('/api/v1/admin/users', queryParameters: {
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'ascending': ascending,
    });
    final data = res.data as Map<String, dynamic>;
    final users = (data['content'] as List)
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
    return (users: users, last: (data['last'] ?? true) as bool);
  }

  Future<void> setActive(int id, bool active) =>
      ApiClient.dio.patch('/api/v1/admin/users/$id/status', data: {'active': active});

  Future<void> setRole(int id, String role) =>
      ApiClient.dio.patch('/api/v1/admin/users/$id/role', data: {'role': role});

  Future<void> unlock(int id) =>
      ApiClient.dio.patch('/api/v1/admin/users/$id/unlock');
}

// ══════════════════════════════════════════════════════════════
//  CONTROLLER (state + pagination + optimistic mutations)
// ══════════════════════════════════════════════════════════════

enum LoadState { idle, loading, error }

class _AdminUsersController extends ChangeNotifier {
  final _AdminService _service = _AdminService();

  final List<AdminUser> users = [];
  LoadState state = LoadState.idle;
  String? error;

  int _page = 0;
  bool _last = false;
  bool _fetching = false;
  static const int _size = 20;

  bool get canLoadMore => !_last && !_fetching;

  Future<void> refresh() async {
    _page = 0;
    _last = false;
    users.clear();
    state = LoadState.loading;
    error = null;
    notifyListeners();
    await _load();
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    await _load();
  }

  Future<void> _load() async {
    _fetching = true;
    try {
      final result = await _service.fetchUsers(page: _page, size: _size);
      users.addAll(result.users);
      _last = result.last;
      _page += 1;
      state = LoadState.idle;
      error = null;
    } on DioException catch (e) {
      state = LoadState.error;
      error = e.response?.statusCode == 403
          ? 'Access denied — admin only.'
          : 'Failed to load users. Check connection.';
    } catch (_) {
      state = LoadState.error;
      error = 'Unexpected error loading users.';
    } finally {
      _fetching = false;
      notifyListeners();
    }
  }

  // Optimistic update: change UI immediately, revert if the server rejects.
  Future<void> toggleActive(AdminUser u) async {
    final i = users.indexWhere((x) => x.id == u.id);
    if (i == -1) return;
    final prev = users[i];
    users[i] = prev.copyWith(active: !prev.active);
    notifyListeners();
    try {
      await _service.setActive(u.id, users[i].active);
    } catch (e) {
      users[i] = prev;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changeRole(AdminUser u, String role) async {
    final i = users.indexWhere((x) => x.id == u.id);
    if (i == -1) return;
    final prev = users[i];
    users[i] = prev.copyWith(role: role);
    notifyListeners();
    try {
      await _service.setRole(u.id, role);
    } catch (e) {
      users[i] = prev;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> unlock(AdminUser u) async {
    final i = users.indexWhere((x) => x.id == u.id);
    if (i == -1) return;
    final prev = users[i];
    users[i] = prev.copyWith(locked: false);
    notifyListeners();
    try {
      await _service.unlock(u.id);
    } catch (e) {
      users[i] = prev;
      notifyListeners();
      rethrow;
    }
  }

  // Cheap summary stats (fine to compute inline — only current page in memory)
  int get adminCount => users.where((u) => u.isAdmin).length;
  int get lockedCount => users.where((u) => u.locked).length;
  int get inactiveCount => users.where((u) => !u.active).length;
}

// ══════════════════════════════════════════════════════════════
//  DASHBOARD SHELL (responsive: NavigationBar / Rail / Drawer)
// ══════════════════════════════════════════════════════════════

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _controller = _AdminUsersController();
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.refresh(); // auto-load users when dashboard opens
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ApiClient.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  static const _dest = [
    (icon: Icons.people_outline, sel: Icons.people, label: 'Users'),
    (icon: Icons.insights_outlined, sel: Icons.insights, label: 'Overview'),
  ];

  Widget _body() {
    if (_navIndex == 0) return _UsersView(controller: _controller);
    return _OverviewView(controller: _controller);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        if (w >= 1240) return _desktop();
        if (w >= 600) return _tablet();
        return _mobile();
      },
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.refresh(),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      );

  Widget _mobile() => Scaffold(
        appBar: _appBar(),
        body: _body(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: [
            for (final d in _dest)
              NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.sel),
                  label: d.label),
          ],
        ),
      );

  Widget _tablet() => Scaffold(
        appBar: _appBar(),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _navIndex,
              onDestinationSelected: (i) => setState(() => _navIndex = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _dest)
                  NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.sel),
                      label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _body()),
          ],
        ),
      );

  Widget _desktop() => Scaffold(
        body: Row(
          children: [
            NavigationDrawer(
              selectedIndex: _navIndex,
              onDestinationSelected: (i) => setState(() => _navIndex = i),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 24, 16, 12),
                  child: Text('Rishvael Admin',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                for (final d in _dest)
                  NavigationDrawerDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.sel),
                      label: Text(d.label)),
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('User Management'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _controller.refresh(),
                    ),
                  ],
                ),
                body: _body(),
              ),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  USERS VIEW (list + pagination + management)
// ══════════════════════════════════════════════════════════════

class _UsersView extends StatefulWidget {
  final _AdminUsersController controller;
  const _UsersView({required this.controller});
  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        widget.controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller;

        if (c.state == LoadState.loading && c.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.state == LoadState.error && c.users.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(c.error ?? 'Error'),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: c.refresh, child: const Text('Retry')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: c.refresh,
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: c.users.length + (c.canLoadMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= c.users.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _UserTile(
                user: c.users[i],
                onToggleActive: () async {
                  try {
                    await c.toggleActive(c.users[i]);
                  } catch (_) {
                    _snack('Could not update status');
                  }
                },
                onChangeRole: (role) async {
                  try {
                    await c.changeRole(c.users[i], role);
                    _snack('Role updated');
                  } catch (_) {
                    _snack('Could not change role');
                  }
                },
                onUnlock: () async {
                  try {
                    await c.unlock(c.users[i]);
                    _snack('Account unlocked');
                  } catch (_) {
                    _snack('Could not unlock');
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onToggleActive;
  final ValueChanged<String> onChangeRole;
  final VoidCallback onUnlock;

  const _UserTile({
    required this.user,
    required this.onToggleActive,
    required this.onChangeRole,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.active
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          child: Text(
            user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(user.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            if (user.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('ADMIN',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: scheme.onTertiaryContainer)),
              ),
            if (user.locked)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.lock, size: 15, color: Colors.orange),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(user.active ? Icons.check_circle : Icons.cancel,
                size: 13,
                color: user.active ? Colors.green : Colors.red),
            const SizedBox(width: 4),
            Text(user.active ? 'Active' : 'Inactive',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            Text('ID ${user.id}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'toggle':
                onToggleActive();
                break;
              case 'make_admin':
                onChangeRole('ROLE_ADMIN');
                break;
              case 'make_customer':
                onChangeRole('ROLE_CUSTOMER');
                break;
              case 'unlock':
                onUnlock();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(user.active ? Icons.block : Icons.check),
                title: Text(user.active ? 'Deactivate' : 'Activate'),
              ),
            ),
            if (!user.isAdmin)
              const PopupMenuItem(
                value: 'make_admin',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.admin_panel_settings),
                  title: Text('Promote to Admin'),
                ),
              ),
            if (user.isAdmin)
              const PopupMenuItem(
                value: 'make_customer',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person),
                  title: Text('Demote to Customer'),
                ),
              ),
            if (user.locked)
              const PopupMenuItem(
                value: 'unlock',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_open),
                  title: Text('Unlock'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  OVERVIEW VIEW (summary cards)
// ══════════════════════════════════════════════════════════════

class _OverviewView extends StatelessWidget {
  final _AdminUsersController controller;
  const _OverviewView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final c = controller;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard(context, 'Loaded Users', '${c.users.length}',
                  Icons.people, Colors.blue),
              _statCard(context, 'Admins', '${c.adminCount}',
                  Icons.admin_panel_settings, Colors.purple),
              _statCard(context, 'Locked', '${c.lockedCount}',
                  Icons.lock, Colors.orange),
              _statCard(context, 'Inactive', '${c.inactiveCount}',
                  Icons.cancel, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(value,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}