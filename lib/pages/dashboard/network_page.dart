import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_view.dart';
import '../../core/responsive.dart';
import '../../models/feed_models.dart';
import '../../providers/dashboard_providers.dart';
import '../profile/widgets/member_avatar.dart';
import 'widgets/section_card.dart';

class NetworkPage extends ConsumerWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(suggestionsProvider);

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        ref.invalidate(suggestionsProvider);
        await ref.read(suggestionsProvider.future);
      },
      child: ReadableWidth(
        maxWidth: 1080,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Network & Connections',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Suggested Connections',
                subtitle: 'People you may know based on your track and interests',
                child: AsyncView<List<ConnectionSuggestion>>(
                  value: suggestionsAsync,
                  onRetry: () => ref.invalidate(suggestionsProvider),
                  data: (suggestions) => suggestions.isEmpty
                      ? const EmptyState(
                          icon: Icons.group_add_outlined,
                          title: 'No suggestions right now',
                          message: 'We will suggest matches as your network grows.',
                        )
                      : Column(
                          children: [
                            for (final person in suggestions) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: MemberAvatar(
                                  name: person.name,
                                  imageUrl: person.avatarUrl,
                                  radius: 22,
                                ),
                                title: Text(person.name),
                                subtitle: Text('${person.headline}\n${person.reason}'),
                                isThreeLine: true,
                                trailing: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.person_add_outlined, size: 18),
                                  label: const Text('Connect'),
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
