import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../pages/business_registration_page.dart';
// TODO: point these at your actual pages.
// import '../auth/signup_page.dart';   // Job Seeker → existing customer signup
// import '../auth/login_page.dart';    // "Already have an account?" link

/// First screen the app shows on a fresh, unauthenticated launch — NOT on
/// every launch. Wire this as the destination only when there's no stored
/// token yet (check ApiClient.readToken() during your app bootstrap, before
/// deciding between this screen and skipping straight to the dashboard).
/// A returning logged-in user should never see a role chooser again.
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = context.breakpoint.atLeastExpanded;
    final options = _roleOptions(context);

    return Scaffold(
      body: SafeArea(
        child: ReadableWidth(
          maxWidth: 900,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Insets.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to Rishvael',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Insets.sm),
                Text(
                  'Tell us why you\'re here so we can set up the right kind of account.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Insets.xxl),
                wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final o in options) ...[
                            Expanded(child: _RoleCard(option: o)),
                            if (o != options.last) SizedBox(width: Insets.md),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          for (final o in options) ...[
                            _RoleCard(option: o),
                            if (o != options.last) SizedBox(height: Insets.md),
                          ],
                        ],
                      ),
                SizedBox(height: Insets.xl),
                TextButton(
                  onPressed: () {
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(builder: (_) => const LoginPage()),
                    // );
                  },
                  child: const Text('Already have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_RoleOption> _roleOptions(BuildContext context) => [
        _RoleOption(
          icon: Icons.search_rounded,
          title: 'Job Seeker',
          subtitle: 'Find and apply to finance opportunities',
          onTap: () {
            // Navigator.of(context).push(
            //   MaterialPageRoute(builder: (_) => const SignupPage()),
            // );
          },
        ),
        _RoleOption(
          icon: Icons.business_rounded,
          title: 'Business',
          subtitle: 'Post opportunities and hire finance professionals',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BusinessRegistrationPage()),
          ),
        ),
        _RoleOption(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Advisor / Expert',
          subtitle: 'Offer advisory services on the platform',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Advisor registration is coming soon.')),
          ),
        ),
      ];
}

class _RoleOption {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.option});

  final _RoleOption option;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: Radii.card),
      child: InkWell(
        borderRadius: Radii.card,
        onTap: option.onTap,
        child: Padding(
          padding: EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 32, color: colors.primary),
              SizedBox(height: Insets.md),
              Text(option.title, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: Insets.xs),
              Text(
                option.subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}