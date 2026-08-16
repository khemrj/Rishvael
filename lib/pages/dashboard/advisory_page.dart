import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_view.dart';
import '../../core/responsive.dart';
import '../../models/feed_models.dart';
import '../../providers/dashboard_providers.dart';
import 'widgets/section_card.dart';

class AdvisoryPage extends ConsumerWidget {
  const AdvisoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advisoryAsync = ref.watch(advisoryProvider);

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        ref.invalidate(advisoryProvider);
        await ref.read(advisoryProvider.future);
      },
      child: ReadableWidth(
        maxWidth: 1080,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Advisory & Mentorship',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Your Advisory Sessions',
                subtitle: 'Upcoming guidance sessions with industry mentors',
                child: AsyncView<List<AdvisorySession>>(
                  value: advisoryAsync,
                  onRetry: () => ref.invalidate(advisoryProvider),
                  data: (sessions) => sessions.isEmpty
                      ? const EmptyState(
                          icon: Icons.forum_outlined,
                          title: 'No advisory sessions booked',
                          message: 'Connect with a mentor to schedule a session.',
                        )
                      : Column(
                          children: [
                            for (final s in sessions) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline_rounded),
                                ),
                                title: Text(s.topic),
                                subtitle: Text('Mentor: ${s.mentorName}'),
                                trailing: Chip(label: Text(s.status)),
                              ),
                              const Divider(),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
