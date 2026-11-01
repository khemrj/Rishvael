// lib/pages/dashboard/people_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/pages/dashboard/chat_screen.dart';

enum ConnectionStatus { none, requested, connected }

class PersonSummary {
  const PersonSummary({
    required this.id,
    required this.name,
    required this.headline,
    required this.status,
  });

  final int id;
  final String name;
  final String headline;
  final ConnectionStatus status;

  PersonSummary copyWith({ConnectionStatus? status}) => PersonSummary(
        id: id,
        name: name,
        headline: headline,
        status: status ?? this.status,
      );
}

/// Replace these with your repository calls to /api/v1/members/search
/// and /api/v1/connections. Kept in one notifier so the UI never talks
/// to the network directly.
class PeopleNotifier extends AutoDisposeAsyncNotifier<List<PersonSummary>> {
  @override
  Future<List<PersonSummary>> build() async => const [];

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // TODO: call GET /api/v1/members/search?q=$q
      return const <PersonSummary>[];
    });
  }

  Future<void> sendConnectionRequest(int personId) async {
    final current = state.value ?? const [];
    state = AsyncData([
      for (final p in current)
        p.id == personId ? p.copyWith(status: ConnectionStatus.requested) : p,
    ]);
    // TODO: call POST /api/v1/connections/{personId}
  }
}

final peopleProvider =
    AsyncNotifierProvider.autoDispose<PeopleNotifier, List<PersonSummary>>(
  PeopleNotifier.new,
);

class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider);
    final notifier = ref.read(peopleProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: notifier.search,
            decoration: InputDecoration(
              hintText: 'Search people by name or role',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _search.clear();
                  notifier.search('');
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: people.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(
              child: Text('Could not load people. Try again.'),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'Search for people to connect with.',
                    style: TextStyle(color: AppColors.ivoryMuted),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = list[i];
                  return _PersonTile(
                    person: p,
                    onConnect: () => notifier.sendConnectionRequest(p.id),
                    onMessage: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(
                          conversationId: p.id,
                          title: p.name,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.onConnect,
    required this.onMessage,
  });

  final PersonSummary person;
  final VoidCallback onConnect;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = person.status == ConnectionStatus.connected;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.gold.withValues(alpha: 0.15),
            child: Text(
              person.name.isEmpty ? '?' : person.name[0].toUpperCase(),
              style: const TextStyle(color: AppColors.gold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  person.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.ivoryMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          switch (person.status) {
            ConnectionStatus.none => FilledButton(
                onPressed: onConnect,
                child: const Text('Connect'),
              ),
            ConnectionStatus.requested => const OutlinedButton(
                onPressed: null,
                child: Text('Pending'),
              ),
            ConnectionStatus.connected => OutlinedButton.icon(
                onPressed: connected ? onMessage : null,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Message'),
              ),
          },
        ],
      ),
    );
  }
}