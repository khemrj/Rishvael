import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/dashboard_providers.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.verified = false,
    this.radius = 20,
  });

  final String name;
  final String? imageUrl;
  final bool verified;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join();

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
          ? NetworkImage(imageUrl!)
          : null,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Text(
              initials,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );

    if (!verified) return avatar;

    // FIX: Constrain the Stack with a SizedBox so it doesn't expand infinitely in a Row/AppBar
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                color: AppColors.gold,
                size: radius * 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({
    super.key,
    required this.onOpenProfile,
    required this.onSignOut,
  });

  final VoidCallback onOpenProfile;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider.select((p) => p.value));
    final name = profile?.fullName ?? 'User';
    final avatarUrl = profile?.avatarUrl;
    final isVerified = profile?.isVerified ?? false;

    return PopupMenuButton<int>(
      tooltip: 'Account menu',
      offset: const Offset(0, 48),
      icon: MemberAvatar(
        name: name,
        imageUrl: avatarUrl,
        verified: isVerified,
        radius: 16,
      ),
      onSelected: (item) {
        if (item == 0) {
          onOpenProfile();
        } else if (item == 1) {
          onSignOut();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 20),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              SizedBox(width: 12),
              Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }
}