import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive.dart';
import '../../core/api_failure.dart';

import '../../core/async_view.dart';
import '../../providers/dashboard_providers.dart';
import '../dashboard/widgets/section_card.dart';
import '../../models/user_profile.dart';
import 'widgets/member_avatar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);

    return AsyncView(
      value: async,
      onRetry: () => ref.invalidate(profileProvider),
      data: (profile) => RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          await ref.read(profileProvider.future);
        },
        child: ReadableWidth(
          maxWidth: 1080,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _ProfileHeader(profile: profile)),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverLayoutBuilder(
                builder: (context, c) {
                  final slot = WindowSize.fromWidth(c.crossAxisExtent);
                  return SliverToBoxAdapter(
                    child: slot.atLeastExpanded
                        ? _WideBody(profile: profile)
                        : _NarrowBody(profile: profile),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Identity block. Everything a recruiter needs in the first 200px:
/// who, what tier, verified or not, where, and how to act on it.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SlotBuilder(
      builder: (context, slot) {
        final identity = Column(
          crossAxisAlignment: slot.isCompact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${profile.track.tier} · ${profile.track.label.toUpperCase()}',
                style: t.labelSmall),
            const SizedBox(height: 6),
            Text(profile.fullName,
                style: t.displaySmall,
                textAlign: slot.isCompact ? TextAlign.center : TextAlign.start),
            if (profile.headline.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(profile.headline,
                  style: t.bodyLarge,
                  textAlign: slot.isCompact ? TextAlign.center : TextAlign.start),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment:
                  slot.isCompact ? WrapAlignment.center : WrapAlignment.start,
              spacing: 14,
              runSpacing: 6,
              children: [
                if (profile.location.isNotEmpty)
                  _MetaBit(icon: Icons.place_outlined, text: profile.location),
                _MetaBit(
                    icon: Icons.link_rounded,
                    text: '${profile.connections} connections'),
                _MetaBit(
                    icon: Icons.visibility_outlined,
                    text: '${profile.profileViews} profile views'),
              ],
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: slot.isCompact ? WrapAlignment.center : WrapAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: () => _openEditor(context, ref, profile),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit profile'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share'),
            ),
          ],
        );

        final avatar = Stack(
          children: [
            MemberAvatar(
              name: profile.fullName,
              imageUrl: profile.avatarUrl,
              verified: profile.isVerified,
              radius: slot.isCompact ? 44 : 52,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: scheme.surface,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Change photo',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {},
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
              ),
            ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              if (slot.isCompact)
                Column(children: [
                  avatar,
                  const SizedBox(height: 14),
                  identity,
                  const SizedBox(height: 16),
                  actions,
                ])
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 20),
                    Expanded(child: identity),
                    const SizedBox(width: 20),
                    actions,
                  ],
                ),
              if (!profile.isVerified) ...[
                const SizedBox(height: 16),
                _VerificationBanner(state: profile.verification),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetaBit extends StatelessWidget {
  const _MetaBit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.state});

  final VerificationState state;

  @override
  Widget build(BuildContext context) {
    final pending = state == VerificationState.pending;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: Radii.card,
        color: AppColors.gold.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pending
                  ? 'Verification in review. We will email you within two working days.'
                  : 'Verify your credentials — verified members appear first in search.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (!pending)
            TextButton(onPressed: () {}, child: const Text('Verify')),
        ],
      ),
    );
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(children: [
              _AboutSection(profile: profile),
              const SizedBox(height: 16),
              _ExperienceSection(profile: profile),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(children: [
              _AvailabilitySection(profile: profile),
              const SizedBox(height: 16),
              _FocusSection(profile: profile),
              const SizedBox(height: 16),
              _CredentialsSection(profile: profile),
            ]),
          ),
        ],
      );
}

class _NarrowBody extends StatelessWidget {
  const _NarrowBody({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _AvailabilitySection(profile: profile),
          const SizedBox(height: 16),
          _AboutSection(profile: profile),
          const SizedBox(height: 16),
          _FocusSection(profile: profile),
          const SizedBox(height: 16),
          _ExperienceSection(profile: profile),
          const SizedBox(height: 16),
          _CredentialsSection(profile: profile),
        ],
      );
}

/// The one place the profile page WRITES. Optimistic, so the switch flips
/// under the thumb with no perceptible delay.
class _AvailabilitySection extends ConsumerWidget {
  const _AvailabilitySection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> toggle(bool v) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(profileProvider.notifier).setOpenToWork(v);
      } on ApiFailure catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }

    return SectionCard(
      title: 'Availability',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: profile.openToWork,
            onChanged: toggle,
            title: const Text('Open to opportunities'),
            subtitle: const Text('Recruiters on Rishvael can see this'),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: profile.openToMentor,
            onChanged: (_) {},
            title: const Text('Available to advise'),
            subtitle: const Text('Graduates can request sessions with you'),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => SectionCard(
        title: 'About',
        child: profile.about.isEmpty
            ? const EmptyState(
                icon: Icons.description_outlined,
                title: 'No summary yet',
                message: 'Two or three sentences on what you do and what you want next.',
              )
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(profile.about,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
      );
}

class _FocusSection extends StatelessWidget {
  const _FocusSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => SectionCard(
        title: 'Focus areas',
        subtitle: 'What we match you on',
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: profile.focusAreas.isEmpty
              ? const EmptyState(
                  icon: Icons.interests_outlined,
                  title: 'None selected',
                  message: 'Pick three to start receiving matched roles.',
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in profile.focusAreas) Chip(label: Text(f)),
                  ],
                ),
        ),
      );
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Experience',
      trailing: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Add experience',
      ),
      child: profile.experience.isEmpty
          ? const EmptyState(
              icon: Icons.work_history_outlined,
              title: 'No experience listed',
              message: 'Add a role — even an internship counts here.',
            )
          : Column(
              children: [
                for (final e in profile.experience)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.business_outlined, size: 20),
                    ),
                    title: Text(e.role, style: t.titleMedium),
                    subtitle: Text('${e.organisation} · ${e.period}'),
                  ),
              ],
            ),
    );
  }
}

class _CredentialsSection extends StatelessWidget {
  const _CredentialsSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => SectionCard(
        title: 'Credentials',
        child: profile.credentials.isEmpty
            ? const EmptyState(
                icon: Icons.school_outlined,
                title: 'No credentials',
                message: 'CFA, ACCA, CPA, degrees — these drive verification.',
              )
            : Column(
                children: [
                  for (final c in profile.credentials)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: Text(c.name),
                      subtitle: Text(
                          [c.issuer, if (c.year != null) '${c.year}'].join(' · ')),
                    ),
                ],
              ),
      );
}

// ---------------------------------------------------------------------------
// EDITOR
// ---------------------------------------------------------------------------

Future<void> _openEditor(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) {
  final editor = _ProfileEditor(profile: profile);

  if (context.breakpoint.atLeastExpanded) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(padding: const EdgeInsets.all(24), child: editor),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
      ),
      child: editor,
    ),
  );
}

class _ProfileEditor extends ConsumerStatefulWidget {
  const _ProfileEditor({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<_ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _headline = TextEditingController(text: widget.profile.headline);
  late final _about = TextEditingController(text: widget.profile.about);
  bool _saving = false;

  @override
  void dispose() {
    // Every controller you create, you dispose. No exceptions.
    for (final c in [_name, _headline, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(profileProvider.notifier).save(
            widget.profile.copyWith(
              fullName: _name.text.trim(),
              headline: _headline.text.trim(),
              about: _about.text.trim(),
            ),
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit profile',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Your name is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _headline,
              maxLength: 90,
              decoration: const InputDecoration(
                labelText: 'Headline',
                hintText: 'Equity Research Associate · Emerging Markets',
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _about,
              maxLines: 5,
              // Long-form on mobile: newline action, not "done".
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(labelText: 'About'),
            ),
            const SizedBox(height: 22),
            FilledButton(
              // Disabled while saving — the cheapest double-submit guard there is.
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
