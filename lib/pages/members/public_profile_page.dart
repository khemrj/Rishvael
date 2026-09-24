import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';


/// Public profile shown to connections, members, and businesses.
///
/// This page is intentionally read-only.
/// Editing belongs to a separate "Edit Profile" screen.
class PublicProfilePage extends StatefulWidget {
  final PublicProfile profile;

  const PublicProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<PublicProfilePage> createState() =>
      _PublicProfilePageState();
}

class _PublicProfilePageState
    extends State<PublicProfilePage> {
  int _selectedTab = 0;

  static const _tabs = [
    'About',
    'Experience',
    'Skills',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,

      appBar: AppBar(
        backgroundColor: AppColors.navy,

        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Share profile',
            onPressed: _shareProfile,
            icon: const Icon(
              Icons.share_outlined,
            ),
          ),

          IconButton(
            tooltip: 'More options',
            onPressed: _showMoreOptions,
            icon: const Icon(
              Icons.more_horiz_rounded,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding =
              constraints.maxWidth >= 900
                  ? 32.0
                  : 16.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),

              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),

                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      32,
                    ),

                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          ProfileHeaderCard(
                            profile: widget.profile,
                            onConnect: _connect,
                            onMessage: _message,
                          ),

                          const SizedBox(height: 20),

                          ProfileTabBar(
                            tabs: _tabs,
                            selectedIndex: _selectedTab,
                            onChanged: (index) {
                              setState(() {
                                _selectedTab = index;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          AnimatedSwitcher(
                            duration: const Duration(
                              milliseconds: 280,
                            ),
                            switchInCurve:
                                Curves.easeOutCubic,
                            switchOutCurve:
                                Curves.easeInCubic,

                            transitionBuilder: (
                              child,
                              animation,
                            ) {
                              final slide =
                                  Tween<Offset>(
                                begin:
                                    const Offset(0.03, 0),
                                end: Offset.zero,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },

                            child: _buildTabContent(),
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
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return AboutSection(
          key: const ValueKey('about'),
          profile: widget.profile,
        );

      case 1:
        return ExperienceSection(
          key: const ValueKey('experience'),
          experiences: widget.profile.experiences,
        );

      case 2:
        return SkillsSection(
          key: const ValueKey('skills'),
          skills: widget.profile.skills,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _connect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection request sent'),
      ),
    );
  }

  void _message() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening conversation...'),
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile link copied'),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.navyCard,

      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.bookmark_border_rounded,
                  color: AppColors.gold,
                ),
                title: const Text('Save profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.gold,
                ),
                title: const Text('Report profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// PROFILE HEADER
// ============================================================================

class ProfileHeaderCard extends StatelessWidget {
  final PublicProfile profile;
  final VoidCallback onConnect;
  final VoidCallback onMessage;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.onConnect,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.none,

      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;

          final coverHeight =
              constraints.maxWidth / 3.6;

          final avatarSize = isWide ? 104.0 : 88.0;

          return Stack(
            clipBehavior: Clip.none,

            children: [
              Column(
                children: [
                  // ----------------------------------------------------------
                  // COVER
                  // ----------------------------------------------------------

                  SizedBox(
                    height: coverHeight,
                    width: double.infinity,

                    child: _CoverImage(
                      imageUrl: profile.coverImageUrl,
                    ),
                  ),

                  // ----------------------------------------------------------
                  // PROFILE INFORMATION
                  // ----------------------------------------------------------

                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 20,

                      avatarSize / 2 + 18,

                      isWide ? 28 : 20,

                      24,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          profile.headline,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color:
                                    AppColors.ivoryMuted,
                              ),
                        ),

                        const SizedBox(height: 8),

                        _ProfileMeta(
                          location: profile.location,
                          industry: profile.industry,
                        ),

                        if (profile.openToOpportunities)
                          const Padding(
                            padding: EdgeInsets.only(
                              top: 16,
                            ),
                            child: _OpenToOpportunitiesBadge(),
                          ),

                        const SizedBox(height: 20),

                        _ProfileActions(
                          isWide: isWide,
                          onConnect: onConnect,
                          onMessage: onMessage,
                        ),

                        const SizedBox(height: 24),

                        const Divider(),

                        const SizedBox(height: 18),

                        _ProfileStats(
                          profile: profile,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // --------------------------------------------------------------
              // AVATAR
              // --------------------------------------------------------------

              Positioned(
                left: isWide ? 28 : 20,

                top:
                    coverHeight - avatarSize / 2,

                child: Hero(
                  tag:
                      'profile-avatar-${profile.id}',

                  child: ProfileAvatar(
                    name: profile.name,
                    imageUrl:
                        profile.profileImageUrl,
                    size: avatarSize,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// COVER IMAGE
// ============================================================================

class _CoverImage extends StatelessWidget {
  final String? imageUrl;

  const _CoverImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            AppColors.navy,
            AppColors.navyCard,
            AppColors.navy,
          ],
        ),

        image: imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              ),
      ),

      child: imageUrl == null
          ? Center(
              child: Icon(
                Icons.auto_graph_rounded,
                size: 48,
                color:
                    AppColors.gold.withValues(
                  alpha: 0.30,
                ),
              ),
            )
          : null,
    );
  }
}

// ============================================================================
// PROFILE AVATAR
// ============================================================================

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.size,
  });

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'));

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: AppColors.navyCard,

        border: Border.all(
          color: AppColors.navy,
          width: 5,
        ),
      ),

      child: ClipOval(
        child: imageUrl == null
            ? Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: size * 0.30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,

                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: size * 0.30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ============================================================================
// PROFILE META
// ============================================================================

class _ProfileMeta extends StatelessWidget {
  final String location;
  final String industry;

  const _ProfileMeta({
    required this.location,
    required this.industry,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,

      children: [
        _MetaItem(
          icon: Icons.location_on_outlined,
          text: location,
        ),

        _MetaItem(
          icon: Icons.business_center_outlined,
          text: industry,
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 18,
          child: Icon(
            Icons.circle,
            size: 4,
            color: AppColors.gold,
          ),
        ),

        const SizedBox(width: 4),

        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: AppColors.ivoryMuted,
              ),
        ),
      ],
    );
  }
}

// ============================================================================
// OPEN TO OPPORTUNITIES
// ============================================================================

class _OpenToOpportunitiesBadge extends StatelessWidget {
  const _OpenToOpportunitiesBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        border: Border.all(
          color: AppColors.gold,
        ),

        color: AppColors.gold.withValues(
          alpha: 0.08,
        ),
      ),

      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 16,
            color: AppColors.gold,
          ),

          SizedBox(width: 7),

          Text(
            'Open to opportunities',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROFILE ACTIONS
// ============================================================================

class _ProfileActions extends StatelessWidget {
  final bool isWide;
  final VoidCallback onConnect;
  final VoidCallback onMessage;

  const _ProfileActions({
    required this.isWide,
    required this.onConnect,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = [
      Expanded(
        child: FilledButton.icon(
          onPressed: onConnect,

          icon: const Icon(
            Icons.person_add_alt_1_rounded,
          ),

          label: const Text(
            'Connect',
          ),
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: OutlinedButton.icon(
          onPressed: onMessage,

          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
          ),

          label: const Text(
            'Message',
          ),
        ),
      ),

      const SizedBox(width: 10),

      SizedBox(
        width: 52,
        height: 48,

        child: OutlinedButton(
          onPressed: () {
            _showActions(context);
          },

          child: const Icon(
            Icons.more_horiz_rounded,
          ),
        ),
      ),
    ];

    if (isWide) {
      return Row(
        children: buttons,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                ),
                label: const Text('Connect'),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: onMessage,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                ),
                label: const Text('Message'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () {
            _showActions(context);
          },
          icon: const Icon(
            Icons.more_horiz_rounded,
          ),
          label: const Text(
            'More actions',
          ),
        ),
      ],
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.navyCard,

      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.bookmark_border_rounded,
                  color: AppColors.gold,
                ),
                title: const Text(
                  'Save profile',
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.share_outlined,
                  color: AppColors.gold,
                ),
                title: const Text(
                  'Share profile',
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.gold,
                ),
                title: const Text(
                  'Report profile',
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// PROFILE STATS
// ============================================================================

class _ProfileStats extends StatelessWidget {
  final PublicProfile profile;

  const _ProfileStats({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            value: profile.connections,
            label: 'Connections',
          ),
        ),

        _StatDivider(),

        Expanded(
          child: _StatItem(
            value: profile.experienceYears,
            label: 'Years experience',
          ),
        ),

        _StatDivider(),

        Expanded(
          child: _StatItem(
            value: '${profile.skills.length}',
            label: 'Skills',
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,

          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                color: AppColors.ivory,
                fontWeight: FontWeight.w600,
              ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          textAlign: TextAlign.center,

          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                color: AppColors.ivoryMuted,
              ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 1,

      color: AppColors.gold.withValues(
        alpha: 0.20,
      ),
    );
  }
}

// ============================================================================
// TAB BAR
// ============================================================================

class ProfileTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ProfileTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: AppColors.navyCard,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: AppColors.gold.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Row(
        children: List.generate(
          tabs.length,

          (index) {
            final selected =
                index == selectedIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),

                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 220,
                  ),

                  curve: Curves.easeOutCubic,

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 11,
                  ),

                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.gold
                        : Colors.transparent,

                    borderRadius:
                        BorderRadius.circular(11),
                  ),

                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(
                      milliseconds: 220,
                    ),

                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.navy
                          : AppColors.ivoryMuted,
                    ),

                    child: Text(
                      tabs[index],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// ABOUT
// ============================================================================

class AboutSection extends StatelessWidget {
  final PublicProfile profile;

  const AboutSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            'About',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 14),

          Text(
            profile.about,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  color: AppColors.ivoryMuted,
                  height: 1.65,
                ),
          ),

          if (profile.website != null) ...[
            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: () {
                // TODO:
                // Launch the website with url_launcher.
              },

              icon: const Icon(
                Icons.language_rounded,
              ),

              label: Text(
                profile.website!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// EXPERIENCE
// ============================================================================

class ExperienceSection extends StatelessWidget {
  final List<ProfessionalExperience> experiences;

  const ExperienceSection({
    super.key,
    required this.experiences,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            'Experience',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 20),

          if (experiences.isEmpty)
            const _EmptyState(
              icon: Icons.work_outline_rounded,
              message:
                  'No experience has been added yet.',
            )
          else
            ...experiences.map(
              (experience) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 24,
                  ),

                  child: ExperienceItem(
                    experience: experience,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class ExperienceItem extends StatelessWidget {
  final ProfessionalExperience experience;

  const ExperienceItem({
    super.key,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          width: 44,
          height: 44,

          decoration: BoxDecoration(
            color: AppColors.gold.withValues(
              alpha: 0.10,
            ),

            borderRadius:
                BorderRadius.circular(12),
          ),

          child: const Icon(
            Icons.business_center_outlined,
            color: AppColors.gold,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                experience.role,

                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),

              const SizedBox(height: 4),

              Text(
                experience.company,

                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                experience.period,

                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color:
                          AppColors.ivoryMuted,
                    ),
              ),

              const SizedBox(height: 10),

              Text(
                experience.description,

                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color:
                          AppColors.ivoryMuted,
                      height: 1.55,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SKILLS
// ============================================================================

class SkillsSection extends StatelessWidget {
  final List<String> skills;

  const SkillsSection({
    super.key,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            'Skills',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 18),

          if (skills.isEmpty)
            const _EmptyState(
              icon: Icons.code_rounded,
              message:
                  'No skills have been added yet.',
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: skills.map(
                (skill) {
                  return Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),

                    decoration: BoxDecoration(
                      color: AppColors.gold
                          .withValues(
                        alpha: 0.08,
                      ),

                      borderRadius:
                          BorderRadius.circular(30),

                      border: Border.all(
                        color: AppColors.gold
                            .withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),

                    child: Text(
                      skill,

                      style: const TextStyle(
                        color:
                            AppColors.ivory,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMMON SECTION CARD
// ============================================================================

class ProfileSectionCard extends StatelessWidget {
  final Widget child;

  const ProfileSectionCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 24,
        ),

        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: AppColors.ivoryMuted,
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: AppColors.ivoryMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class PublicProfile {
  final int id;

  final String name;
  final String headline;

  final String location;
  final String industry;

  final String about;

  final String connections;
  final String experienceYears;

  final bool openToOpportunities;

  final String? website;

  final String? profileImageUrl;
  final String? coverImageUrl;

  final List<ProfessionalExperience> experiences;
  final List<String> skills;

  const PublicProfile({
    required this.id,
    required this.name,
    required this.headline,
    required this.location,
    required this.industry,
    required this.about,
    required this.connections,
    required this.experienceYears,
    required this.openToOpportunities,
    this.website,
    this.profileImageUrl,
    this.coverImageUrl,
    this.experiences = const [],
    this.skills = const [],
  });
}

class ProfessionalExperience {
  final String role;
  final String company;
  final String period;
  final String description;

  const ProfessionalExperience({
    required this.role,
    required this.company,
    required this.period,
    required this.description,
  });
}