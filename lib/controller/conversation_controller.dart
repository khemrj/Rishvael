import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/models/conversations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() => fetchConversations();

  Future<List<Conversation>> fetchConversations() async {
    debugPrint('📡 [ConversationsNotifier] Fetching conversations...');

    final Response<Map<String, dynamic>> response = await ApiClient.dio.get<Map<String, dynamic>>(
      '/api/chat/me/conversations',
      options: ApiClient.strict,
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception('Unexpected response from server');
    }

    final data = (body['data'] as List?) ?? const [];
    final list = data
        .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
        .toList();

    debugPrint('✅ [ConversationsNotifier] Loaded ${list.length} conversations.');
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(fetchConversations);
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);