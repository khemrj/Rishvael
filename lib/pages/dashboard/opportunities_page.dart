import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_view.dart';
import '../../core/responsive.dart';
import '../../models/feed_models.dart';
import '../../providers/dashboard_providers.dart';
import 'widgets/section_card.dart';

class OpportunitiesPage extends ConsumerWidget {
  const OpportunitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunitiesAsync = ref.watch(opportunitiesProvider);
    final selectedFilter = ref.watch(opportunityFilterProvider);

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        ref.invalidate(opportunitiesProvider);
        await ref.read(opportunitiesProvider.future);
      },
      child: ReadableWidth(
        maxWidth: 1080,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Opportunities', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedFilter == null,
                      onSelected: (_) => ref
                          .read(opportunityFilterProvider.notifier)
                          .select(null),
                    ),
                    const SizedBox(width: 8),
                    for (final k in OpportunityKind.values) ...[
                      FilterChip(
                        label: Text(k.name.toUpperCase()),
                        selected: selectedFilter == k,
                        onSelected: (_) => ref
                            .read(opportunityFilterProvider.notifier)
                            .select(k),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Available Positions',
                child: AsyncView<List<Opportunity>>(
                  value: opportunitiesAsync,
                  onRetry: () => ref.invalidate(opportunitiesProvider),
                  data: (list) => list.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matching opportunities',
                          message: 'Try clearing your filters or search query.',
                        )
                      : Column(
                          children: [
                            for (final item in list) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Icon(
                                    item.kind == OpportunityKind.internship
                                        ? Icons.school_outlined
                                        : Icons.business_center_outlined,
                                  ),
                                ),
                                title: Text(item.title),
                                subtitle: Text('${item.company} · ${item.location}'),
                                trailing: FilledButton(
                                  onPressed: () {
                                    ref.read(applyToOpportunityProvider)(item.id);
                                  },
                                  child: const Text('Apply'),
                                ),
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
