import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'package:flutter_application_1/pages/setup_pages/company_setup_page.dart';
import 'package:flutter_application_1/pages/setup_pages/member_setup_page.dart';
import 'package:flutter_application_1/pages/setup_pages/professional_setup_page.dart';
import '../core/responsive.dart';

/// Available role options in Rishvael system.
enum UserRole {
  freshGraduate,
  workingProfessional,
  business;

  String get title => switch (this) {
    UserRole.freshGraduate => 'Fresh graduate',
    UserRole.workingProfessional => 'Working professional',
    UserRole.business => 'Business',
  };

  String get subtitle => switch (this) {
    UserRole.freshGraduate =>
      'Start your career with mentorship and your first opportunities',
    UserRole.workingProfessional =>
      'Grow your network and reach higher-value roles',
    UserRole.business => 'Find and hire verified finance talent',
  };

  IconData get icon => switch (this) {
    UserRole.freshGraduate => Icons.school_outlined,
    UserRole.workingProfessional => Icons.work_outline,
    UserRole.business => Icons.domain_outlined,
  };
}

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key, this.onRoleConfirmed, this.onLoginTap});

  final ValueChanged<UserRole>? onRoleConfirmed;
  final VoidCallback? onLoginTap;

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  UserRole? _selectedRole;
  void _continueWithSelectedRole() {
    final role = _selectedRole;

    if (role == null) return;

    final Widget destination = switch (role) {
      UserRole.business => const CompanySetupPage(),
      UserRole.freshGraduate => const MemberSetupPage(),
      UserRole.workingProfessional => const ProfessionalSetupPage(),
    };

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
  }

  // Custom Gold Palette (Balanced dark, bright & subtle gold tones)
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark = Color.fromARGB(255, 176, 145, 66);
  static const Color goldSubtle = Color(0x40C5A059);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A111E), // Dark Navy Background
      body: SafeArea(
        child: ReadableWidth(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const minRequiredHeight = 620.0;
              final isTallEnough = constraints.maxHeight >= minRequiredHeight;

              final mainContent = Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Insets.page.of(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Logo & Brand Bar
                    const _TopBarSection(),
                    const SizedBox(height: Insets.lg),

                    // Header Section
                    const _HeaderSection(),
                    const SizedBox(height: Insets.xl),

                    // Dynamic Responsive Card Grid
                    if (isTallEnough)
                      Expanded(
                        child: SlotBuilder(
                          builder: (context, slotSize) {
                            return _RoleGrid(
                              slotSize: slotSize,
                              selectedRole: _selectedRole,
                              onRoleSelected: (role) {
                                setState(() => _selectedRole = role);
                              },
                              isVerticallyBounded: true,
                            );
                          },
                        ),
                      )
                    else
                      SlotBuilder(
                        builder: (context, slotSize) {
                          return _RoleGrid(
                            slotSize: slotSize,
                            selectedRole: _selectedRole,
                            onRoleSelected: (role) {
                              setState(() => _selectedRole = role);
                            },
                            isVerticallyBounded: false,
                          );
                        },
                      ),
                    const SizedBox(height: Insets.xl),

                    // Footer Section (Log In Link)
                    // 3. Footer Section
                    _FooterSection(
                      isEnabled: _selectedRole != null,
                      onPressed: _continueWithSelectedRole,
                      onLoginTap: widget.onLoginTap,
                    ),
                  ],
                ),
              );

              if (isTallEnough) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: mainContent,
                );
              }

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: mainContent,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MODULAR SUB-WIDGETS
// ============================================================================

/// Top branding bar with Diamond 'R' Logo on top-left and 'RISHVAEL' on top-right.

class _TopBarSection extends StatelessWidget {
  const _TopBarSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: Insets.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 36,
            child: Center(
              child: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _RoleSelectionPageState.goldDark,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Transform.rotate(
                    angle: -0.785398,
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: _RoleSelectionPageState.goldPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Text(
            'RISHVAEL',
            style: TextStyle(
              color: _RoleSelectionPageState.goldDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.5,
            ),
          ),
        ],
      ),
    );
  }
}


//The key change is that the logo now has a **fixed `48 × 36` layout area**, while the actual square is rotated inside it. This lets Flutter align the logo and `RISHVAEL` on the same horizontal center line without changing your `Row` spacing behavior.


/// Title and introductory Subtitle.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Welcome to Rishvael',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Text(
          'Tell us who you are so we can set up the right kind of account.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );    
  }
}

/// Grid/Column container managing dynamic responsive card heights.
class _RoleGrid extends StatelessWidget {
  const _RoleGrid({
    required this.slotSize,
    required this.selectedRole,
    required this.onRoleSelected,
    required this.isVerticallyBounded,
  });

  final WindowSize slotSize;
  final UserRole? selectedRole;
  final ValueChanged<UserRole> onRoleSelected;
  final bool isVerticallyBounded;

  @override
  Widget build(BuildContext context) {
    final roles = UserRole.values;

    if (slotSize.isCompact) {
      return Column(
        children: roles.map((role) {
          final cardWidget = Padding(
            padding: const EdgeInsets.only(bottom: Insets.md),
            child: _RoleCard(
              role: role,
              isSelected: selectedRole == role,
              onTap: () => onRoleSelected(role),
            ),
          );

          return isVerticallyBounded ? Expanded(child: cardWidget) : cardWidget;
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: roles.map((role) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
            child: _RoleCard(
              role: role,
              isSelected: selectedRole == role,
              onTap: () => onRoleSelected(role),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Individual Selectable Role Card styled with Golden Outlines and Badges.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const goldPrimary = _RoleSelectionPageState.goldPrimary;
    const goldSubtle = _RoleSelectionPageState.goldSubtle;

    final borderColor = isSelected ? goldPrimary : goldSubtle;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: goldPrimary.withValues(alpha: 0.1),
        highlightColor: goldPrimary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF131D31)
                : const Color(0xFF0E1729),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: goldPrimary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Icon Square Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? goldPrimary : goldSubtle,
                    width: 1.0,
                  ),
                  color: Colors.transparent,
                ),
                child: Icon(
                  role.icon,
                  size: 22,
                  color: isSelected ? goldPrimary : const Color(0xFFB0A288),
                ),
              ),
              const SizedBox(width: Insets.md),

              // Title & Subtitle Stack
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.title,
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? goldPrimary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection({
    required this.isEnabled,
    required this.onPressed,
    this.onLoginTap,
  });

  final bool isEnabled;
  final VoidCallback onPressed;
  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continue Button
        SizedBox(
          height: 52.0,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldDark,
              disabledBackgroundColor: _RoleSelectionPageState.goldDark
                  .withValues(alpha: 0.2),
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isEnabled ? 4 : 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: Insets.md),
//// i wrote it to make iarea biger for touch
        // Log in link below button
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap:(){ Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginPage()));},
            child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 16,
      ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: _RoleSelectionPageState.goldDark),
                  ),
                  TextSpan(
                    text: 'Log in',
                    style: TextStyle(
                      color: _RoleSelectionPageState.goldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ]);
  }
}
