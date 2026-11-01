import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/controller/conversation_controller.dart';
import 'package:flutter_application_1/core/errrors/friendly_message.dart';
import 'package:flutter_application_1/core/responsive.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/models/conversations.dart';
import 'package:flutter_application_1/pages/dashboard/chat_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Chats'),
      ),
      body: SafeArea(
        child: conversations.when(
          loading: () => const _LoadingView(),
          error: (error, _) => _ErrorView(
            message: friendlyMessage(error),
            onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
          ),
          data: (items) => items.isEmpty
              ? const _EmptyView()
              : _ConversationList(items: items),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LIST
// ---------------------------------------------------------------------------

class _ConversationList extends ConsumerWidget {
  const _ConversationList({required this.items});

  final List<Conversation> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.navyCard,
      onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
      child: ReadableWidth(
        maxWidth: 720,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: Insets.sm),
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 84,
            color: AppColors.gold.withValues(alpha: 0.12),
          ),
          itemBuilder: (context, index) => _ConversationTile(
            conversation: items[index],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(
              conversationId: conversation.conversationId,
              title: conversation.receiverUsername,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              _Avatar(
                name: conversation.receiverUsername,
                imageUrl: conversation.receiverProfilePictureUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.receiverUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage ?? 'Say hi 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ivoryMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatTime(conversation.lastMessageAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.ivoryMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final local = dt.toLocal();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m ${local.hour < 12 ? 'AM' : 'PM'}';
    }
    if (now.difference(local).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[local.weekday - 1];
    }
    return '${local.day}/${local.month}/${local.year}';
  }
}

// ---------------------------------------------------------------------------
// PIECES
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final fallback = CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.gold.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: AppColors.gold.withValues(alpha: 0.6),
              ),
              const SizedBox(height: Insets.md),
              Text(
                'No conversations yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ivory,
                    ),
              ),
              const SizedBox(height: Insets.xs),
              Text(
                'Connect with a member to start chatting.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ivoryMuted,
                    ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: AppColors.ivoryMuted,
              ),
              const SizedBox(height: Insets.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ivory,
                    ),
              ),
              const SizedBox(height: Insets.md),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}