import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_view.dart';
import '../../core/responsive.dart';
import '../../models/feed_models.dart';
import '../../providers/dashboard_providers.dart';
import 'widgets/section_card.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunitiesAsync = ref.watch(opportunitiesProvider);
    final applicationsAsync = ref.watch(applicationsProvider);

    return RefreshIndicator.adaptive(
      onRefresh: () => refreshDashboard(ref),
      child: ReadableWidth(
        maxWidth: 1080,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Featured Opportunities',
                subtitle: 'Roles curated for your career track',
                child: AsyncView<List<Opportunity>>(
                  value: opportunitiesAsync,
                  onRetry: () => ref.invalidate(opportunitiesProvider),
                  data: (opportunities) => opportunities.isEmpty
                      ? const EmptyState(
                          icon: Icons.work_outline_rounded,
                          title: 'No opportunities found',
                          message: 'Check back later for fresh roles and internships.',
                        )
                      : Column(
                          children: [
                            for (final opp in opportunities.take(5))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Icon(
                                    opp.kind == OpportunityKind.internship
                                        ? Icons.school_outlined
                                        : Icons.work_outlined,
                                  ),
                                ),
                                title: Text(opp.title),
                                subtitle: Text('${opp.company} · ${opp.location}'),
                                trailing: FilledButton.tonal(
                                  onPressed: () {
                                    ref.read(applyToOpportunityProvider)(opp.id);
                                  },
                                  child: const Text('Apply'),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Your Applications',
                subtitle: 'Track your recent role submissions',
                child: AsyncView<List<ApplicationRecord>>(
                  value: applicationsAsync,
                  onRetry: () => ref.invalidate(applicationsProvider),
                  data: (apps) => apps.isEmpty
                      ? const EmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'No active applications',
                          message: 'Applied positions will appear here.',
                        )
                      : Column(
                          children: [
                            for (final app in apps)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.check_circle_outline_rounded),
                                title: Text(app.roleTitle),
                                subtitle: Text(app.company),
                                trailing: Chip(label: Text(app.status)),
                              ),
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
