import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_client.dart';
import 'core/app_theme.dart';
import 'core/deep_link_handler.dart';
import 'core/responsive.dart';
import 'pages/login_page.dart';
import 'pages/role_selection_page.dart';
// TODO: import your actual dashboard page and swap it in below.
// import 'pages/customer_dashboard_page.dart';

// Global navigator key — lets DeepLinkHandler navigate from outside
// any widget's build context (e.g. when a reset link is tapped).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DeepLinkHandler _deepLinkHandler;

  @override
  void initState() {
    super.initState();
    _deepLinkHandler = DeepLinkHandler(navigatorKey);
    _deepLinkHandler.init();

    // Any unrecoverable session (expired refresh token, revoked access, etc.)
    // bounces the user to login from wherever they are in the app.
    ApiClient.onSessionExpired = () {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rishvael',
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.system,
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: context.clampedTextScaler(max: 1.6),
        ),
        child: child!,
      ),
      home: const AppBootstrap(),
    );
  }
}

/// Decides the first screen the user actually sees:
///   - stored token present  → straight into the app (dashboard)
///   - no stored token       → RoleSelectionPage (Job Seeker / Business / Advisor)
///
/// A stale/expired token still gets through this check — that's fine, it's
/// not this widget's job to validate it. The existing ApiClient 401→refresh
/// flow (and onSessionExpired above) already bounces the user back to
/// LoginPage if the token turns out to be dead.
class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiClient.readToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final hasToken = snapshot.data != null;
        if (hasToken) {
          // TODO: replace with your real dashboard widget.
          return const Placeholder(); // e.g. const CustomerDashboardPage()
        }
        return const RoleSelectionPage();
      },
    );
  }
}