import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/data/user_repository.dart';
import 'package:flutter_application_1/pages/dashboard/chat_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/data/user_dto.dart';

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

    // Constrain the Stack with a SizedBox so it doesn't expand infinitely in a Row/AppBar/ListTile
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

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserDto> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  String _query = '';

  /// Triggers user search with pagination support
  Future<void> _searchUsers({bool loadMore = false}) async {
    if (_isLoading) return;

    if (!loadMore) {
      setState(() {
        _page = 0;
        _users = [];
        _hasMore = true;
      });
    }

    if (!_hasMore && loadMore) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(userRepositoryProvider); 
      
      final (newUsers, hasMoreResult) = await repository.searchUsersByUsername(
        _query,
        page: _page,
        size: 10,
      );

      setState(() {
        if (loadMore) {
          _users.addAll(newUsers);
        } else {
          _users = newUsers;
        }
        _hasMore = hasMoreResult;
        if (newUsers.isNotEmpty) {
          _page++;
        }
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Robust helper to extract conversation ID safely regardless of key or type
  Future<int?> _getOrCreateConversationId(int recipientUserId) async {
    try {
      final dio = ref.read(dioProvider); 
      final response = await dio.post(
        '/api/chat/conversations/direct', 
        data: {'userId': recipientUserId},
      );
      
      debugPrint('Direct conversation response data: ${response.data}');

      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        
        // Check if there is a nested 'conversation' or 'data' object
        final conversationObj = data['conversation'] ?? data['data'] ?? data;
        
        if (conversationObj is Map) {
          final rawId = conversationObj['id'] ?? conversationObj['conversationId'];
          if (rawId != null) {
            if (rawId is int) return rawId;
            return int.tryParse(rawId.toString());
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error opening direct conversation: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search username...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: (value) {
            _query = value.trim();
            _searchUsers(); // Trigger search on input change
          },
        ),
      ),
      body: _users.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Text(
                    'Search for users to start chatting',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _users.length) {
                      // Automatically load next page when scrolled to bottom
                      _searchUsers(loadMore: true);
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final user = _users[index];

                    return ListTile(
                      title: Text(
                        user.username,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'ID: ${user.id}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      // MemberAvatar safely positioned on the right (trailing) side
                      trailing: MemberAvatar(
                        name: user.username,
                        imageUrl: user.userProfileUrl,
                        radius: 22,
                      ),
                      onTap: () async {
                        // 1. Get/Create the conversation ID via backend POST
                        final conversationId = await _getOrCreateConversationId(user.id);

                        // 2. Navigate to your ChatScreen if the conversation ID is valid
                        if (conversationId != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                conversationId: conversationId,
                                title: user.username,
                              ),
                            ),
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open chat with this user.')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
    );
  }
}