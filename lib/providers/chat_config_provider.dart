import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/chat_message.dart';
import 'AuthNotifier.dart';

class ChatConfig {
  const ChatConfig({
    required this.url,
    required this.getToken,
    required this.currentUserId,
    this.fetchSince,
  });

  final String url;
  final Future<String> Function() getToken;
  final int currentUserId;

  /// REST backfill: GET /messages/since?afterId=... Return missed messages.
  final Future<List<ChatMessage>> Function(int? afterId)? fetchSince;
}

final chatConfigProvider = Provider<ChatConfig?>((ref) {
  final auth = ref.watch(authProvider).valueOrNull;
  final userId = auth?.userId;
  final token = auth?.token;

  if (auth?.status != AuthStatus.authenticated ||
      userId == null ||
      token == null) {
    return null;
  }

  final apiUri = Uri.parse(ApiClient.baseUrl);
  final socketUri = apiUri.replace(
    scheme: switch (apiUri.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      _ => apiUri.scheme,
    },
    path: '/ws',
  );

  return ChatConfig(
    url: socketUri.toString(),
    getToken: () async {
      final latestToken = await ApiClient.readToken();
      if (latestToken == null || latestToken.isEmpty) {
        throw StateError('No access token is available for chat.');
      }
      return latestToken;
    },
    currentUserId: userId,
  );
});
