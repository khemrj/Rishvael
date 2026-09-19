import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_failure.dart';
import 'package:flutter_application_1/pages/business_dashboard.dart';
import 'package:flutter_application_1/pages/dashboard/dashboard_router.dart';
import 'package:flutter_application_1/pages/error_page.dart';
import 'package:flutter_application_1/pages/members/public_profile_page.dart';
import 'package:flutter_application_1/pages/splash_screen.dart';
import 'package:flutter_application_1/providers/AuthNotifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_client.dart';

import 'core/deep_link_handler.dart';
import 'core/responsive.dart';
import 'pages/login_page.dart';

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
class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authProvider);

    return authStateAsync.when(
      loading: () => const SplashScreen(),
      error: (error, stackTrace) {
        final failure = ApiFailure.from(error);
        return ErrorPage(
          failure: failure,
          onRetry: () => ref.invalidate(authProvider),
        );
      },
      data: (authState) => switch (authState.status) {
        // The actual fix: authenticated now routes through
        // DashboardRouter, which reads the ALREADY-decoded role off
        // authState — no re-decoding, no duplicate JWT logic anywhere.
        AuthStatus.authenticated =>
          DashboardRouter(role: authState.role),
       AuthStatus.unauthenticated => const PublicProfilePage(
  profile: PublicProfile(
    id: 1,
    name: 'Alex Mercer',
    headline: 'Finance Analyst · Wealth Management',
    location: 'Singapore',
    industry: 'Financial Services',
    about:
        'Finance professional focused on portfolio strategy '
        'and client wealth planning. Four years across '
        'Asia-Pacific markets.',
    connections: '248',
    experienceYears: '4+',
    openToOpportunities: true,
    website: 'alexmercer.com',
    experiences: [
      ProfessionalExperience(
        role: 'Senior Wealth Analyst',
        company: 'Meridian Capital',
        period: '2024 – Present',
        description:
            'Managing investment research, portfolio strategy, '
            'and client wealth planning across Asia-Pacific markets.',
      ),
      ProfessionalExperience(
        role: 'Financial Analyst',
        company: 'Atlas Investments',
        period: '2022 – 2024',
        description:
            'Performed financial analysis, market research, '
            'and portfolio reporting.',
      ),
    ],
    skills: [
      'Financial Analysis',
      'Portfolio Management',
      'Risk Management',
      'Investment Research',
      'Wealth Management',
      'Python',
      'Data Analysis',
    ],
  ),
),
        // No stored token has ever existed → first-launch experience,
        // not the login form. A returning user with a dead/expired
        // token still lands on `unauthenticated` above via
        // ApiClient.onSessionExpired, which already routes to
        // LoginPage directly — RoleSelectionPage is correctly reserved
        // for users who have NEVER logged in on this device.
        AuthStatus.initial => const DashboardScreen(),
      },
    );
  }
}