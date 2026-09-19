// lib/pages/admin_dashboard.dart
import 'package:flutter/material.dart';



// ============================================================
// APP
// ============================================================

class MeridianApp extends StatelessWidget {
  const MeridianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meridian Capital',
      theme: AppTheme.light(),
      home: const DashboardScreen(),
    );
  }
}

// ============================================================
// DESIGN SYSTEM
// ============================================================

abstract final class AppColors {
  static const navy = Color(0xFF0D1B3E);
  static const navyLight = Color(0xFF172B5C);
  static const navySurface = Color(0xFF142653);

  static const gold = Color(0xFFD4AF4A);
  static const goldLight = Color(0xFFE5C766);

  static const white = Color(0xFFF8F9FC);
  static const textSecondary = Color(0xFFAAB6D0);
  static const border = Color(0xFF33456D);

  static const success = Color(0xFF55C98A);
  static const warning = Color(0xFFE5C766);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const small = 12.0;
  static const medium = 18.0;
  static const large = 24.0;
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.gold,
      onPrimary: AppColors.navy,
      surface: AppColors.navy,
      onSurface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.navy,

      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppColors.navySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        height: 76,

        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);

            return TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? AppColors.gold
                  : AppColors.textSecondary,
            );
          },
        ),

        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);

            return IconThemeData(
              size: 23,
              color: selected
                  ? AppColors.gold
                  : AppColors.textSecondary,
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD SCREEN
// ============================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardHome(),
    JobsPage(),
    CandidatesPage(),
    TeamPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,

        // IndexedStack keeps each tab alive.
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),

          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),

          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Candidates',
          ),

          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Team',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME DASHBOARD
// ============================================================

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),

            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),

              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide
                        ? AppSpacing.xxl
                        : AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),

                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        const DashboardHeader(),

                        const SizedBox(
                          height: AppSpacing.xxl,
                        ),

                        const SectionTitle(
                          title: 'Overview',
                          subtitle:
                              'Your business at a glance',
                        ),

                        const SizedBox(
                          height: AppSpacing.lg,
                        ),

                        const StatsSection(),

                        const SizedBox(
                          height: AppSpacing.xl,
                        ),

                        const PrimaryAction(),

                        const SizedBox(
                          height: AppSpacing.xxl,
                        ),

                        const RecentApplicantsSection(),

                        const SizedBox(
                          height: AppSpacing.xxl,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CompanyAvatar(),

        const SizedBox(
          width: AppSpacing.md,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meridian Capital',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),

              SizedBox(height: 3),

              Text(
                'Business dashboard',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const NotificationButton(),
      ],
    );
  }
}

class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,

      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),

      alignment: Alignment.center,

      child: const Text(
        'MC',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION
// ============================================================

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            // TODO: Open notifications screen.
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            size: 28,
          ),
        ),

        Positioned(
          right: 7,
          top: 6,
          child: Container(
            width: 9,
            height: 9,

            decoration: BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.navy,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),

        if (subtitle != null) ...[
          const SizedBox(height: 4),

          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// STATISTICS
// ============================================================

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 950
            ? 4
            : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,

          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,

          childAspectRatio: width >= 950
              ? 1.55
              : 1.45,

          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          children: const [
            StatCard(
              value: '4',
              label: 'Active job posts',
              icon: Icons.work_outline_rounded,
            ),

            StatCard(
              value: '12',
              label: 'New applicants',
              icon: Icons.person_add_alt_1_rounded,
            ),

            StatCard(
              value: '340',
              label: 'Profile views',
              icon: Icons.visibility_outlined,
            ),

            StatCard(
              value: '2/5',
              label: 'Team seats used',
              icon: Icons.groups_outlined,
            ),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.gold,
            ),

            const Spacer(),

            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRIMARY ACTION
// ============================================================

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          // TODO: Navigate to create job page.
        },

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          'Post a job',
        ),

        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,

          minimumSize: const Size(
            double.infinity,
            56,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.medium,
            ),
          ),

          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RECENT APPLICANTS
// ============================================================

class RecentApplicantsSection extends StatelessWidget {
  const RecentApplicantsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Expanded(
              child: SectionTitle(
                title: 'Recent applicants',
              ),
            ),

            TextButton(
              onPressed: () {
                // TODO: Open all candidates.
              },
              child: const Text(
                'View all',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        const ApplicantTile(
          name: 'Daniel Osei',
          position: 'Junior Analyst',
          status: ApplicantStatus.newApplicant,
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        const ApplicantTile(
          name: 'Wei Zhang',
          position: 'Risk Associate',
          status: ApplicantStatus.shortlisted,
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        const ApplicantTile(
          name: 'Amelia Smith',
          position: 'Financial Analyst',
          status: ApplicantStatus.reviewing,
        ),
      ],
    );
  }
}

// ============================================================
// APPLICANT TILE
// ============================================================

enum ApplicantStatus {
  newApplicant,
  shortlisted,
  reviewing,
}

class ApplicantTile extends StatelessWidget {
  final String name;
  final String position;
  final ApplicantStatus status;

  const ApplicantTile({
    super.key,
    required this.name,
    required this.position,
    required this.status,
  });

  String get statusText {
    switch (status) {
      case ApplicantStatus.newApplicant:
        return 'New';

      case ApplicantStatus.shortlisted:
        return 'Shortlisted';

      case ApplicantStatus.reviewing:
        return 'Reviewing';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.md,
        ),

        child: Row(
          children: [
            ApplicantAvatar(
              name: name,
            ),

            const SizedBox(
              width: AppSpacing.md,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Applied: $position',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: AppSpacing.sm,
            ),

            StatusBadge(
              text: statusText,
              filled:
                  status == ApplicantStatus.newApplicant,
            ),
          ],
        ),
      ),
    );
  }
}

class ApplicantAvatar extends StatelessWidget {
  final String name;

  const ApplicantAvatar({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((word) => word[0])
        .join();

    return CircleAvatar(
      radius: 23,

      backgroundColor:
          AppColors.gold.withValues(alpha: 0.15),

      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================

class StatusBadge extends StatelessWidget {
  final String text;
  final bool filled;

  const StatusBadge({
    super.key,
    required this.text,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),

      decoration: BoxDecoration(
        color: filled
            ? AppColors.gold
            : Colors.transparent,

        borderRadius: BorderRadius.circular(30),

        border: filled
            ? null
            : Border.all(
                color: AppColors.border,
              ),
      ),

      child: Text(
        text,
        style: TextStyle(
          color: filled
              ? AppColors.navy
              : AppColors.textSecondary,

          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================
// PLACEHOLDER PAGES
// ============================================================

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Jobs'),
    );
  }
}

class CandidatesPage extends StatelessWidget {
  const CandidatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Candidates'),
    );
  }
}

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Team'),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile'),
    );
  }
}