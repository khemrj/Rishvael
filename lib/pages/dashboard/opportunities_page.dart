import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/opportunity_model.dart';
import '../../providers/dashboard_providers.dart';

class OpportunitiesPage extends ConsumerWidget {
  const OpportunitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunitiesAsync = ref.watch(opportunitiesProvider);

    return RefreshIndicator(
      onRefresh: () => refreshDashboard(ref),
      child: opportunitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ListView(
          children: [
            const SizedBox(height: 120),
            Center(child: Text('Failed to load opportunities:\n$err', textAlign: TextAlign.center)),
          ],
        ),
        data: (opportunities) {
          if (opportunities.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No opportunities available right now.')),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: opportunities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _OpportunityCard(opportunity: opportunities[i]),
          );
        },
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final o = opportunity;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(o.title, style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(o.type.label)),
              ],
            ),
            const SizedBox(height: 4),
            Text(o.businessName, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(o.specialization.label)),
                Chip(label: Text(o.workMode.label)),
                Chip(label: Text(o.experienceLevel.label)),
              ],
            ),
            const SizedBox(height: 8),
            Text(o.location),
            const SizedBox(height: 8),
            Text(o.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(o.compensation.display(), style: Theme.of(context).textTheme.bodyMedium),
                Text('${o.openings} opening${o.openings == 1 ? '' : 's'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}