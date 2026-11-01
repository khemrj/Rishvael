import 'dart:async';

import 'package:flutter_application_1/models/chat_message.dart';
import 'package:flutter_application_1/providers/chat_config_provider.dart';
import 'package:flutter_application_1/socket/chat_socket.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ChatState {
  const ChatState({  
    this.messages = const {},
    this.connection = ConnState.connecting,
  });

  final Map<int, List<ChatMessage>>
  messages; // conversationId -> oldest..newest
  final ConnState connection;

  ChatState copyWith({
    Map<int, List<ChatMessage>>? messages,
    ConnState? connection,
  }) => ChatState(
    messages: messages ?? this.messages,
    connection: connection ?? this.connection,
  );
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  static const _ackTimeout = Duration(seconds: 12);

  late final ChatSocket _socket;
  final _timers = <String, Timer>{};
  final _uuid = const Uuid();

  ChatConfig get _config {
    final config = ref.read(chatConfigProvider);
    if (config == null) {
      throw StateError('ChatConfig must be provided before using chat.');
    }
    return config;
  }

  @override
  ChatState build() {
    ref.watch(chatConfigProvider);
    final cfg = _config;
    _socket = ChatSocket(
      url: cfg.url,
      getToken: cfg.getToken,
      onMessage: _onServerMessage,
      onError: _onServerError,
      onConnected: _onConnected,
    );
    _socket.connection.addListener(_syncConnection);

    ref.onDispose(() {
      _socket.connection.removeListener(_syncConnection);
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
      _socket.dispose();
    });

    Future.microtask(_socket.connect);
    return const ChatState();
  }

  // ---------- public API ----------

  /// Instant: the bubble appears immediately in `sending` state.
  void send(int conversationId, String text) {
    final content = text.trim();
    if (content.isEmpty) return;

    final msg = ChatMessage(
      clientMsgId: _uuid.v4(),
      conversationId: conversationId,
      senderId: _config.currentUserId,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    _put(conversationId, [...?state.messages[conversationId], msg]);
    _transmit(msg);
  }

  /// Re-sends with the SAME clientMsgId (server dedupes).
  void retry(ChatMessage m) {
    _mutate(m.clientMsgId, (x) => x.copyWith(status: MessageStatus.sending));
    _transmit(m);
  }

  void onResume() => _socket.reconnectNow();

  // ---------- sending ----------

  void _transmit(ChatMessage m) {
    _timers.remove(m.clientMsgId)?.cancel();
    final sent = _socket.send(
      conversationId: m.conversationId,
      clientMsgId: m.clientMsgId,
      content: m.content,
    );
    // Offline: stay "sending" with no timer; flushed on reconnect.
    if (!sent) return;
    _timers[m.clientMsgId] = Timer(_ackTimeout, () {
      _timers.remove(m.clientMsgId);
      _mutate(m.clientMsgId, (x) => x.copyWith(status: MessageStatus.failed));
    });
  }

  // ---------- incoming ----------

  void _onServerMessage(Map<String, dynamic> json) {
    try {
      _upsert(ChatMessage.fromJson(json));
    } catch (_) {
      /* malformed frame */
    }
  }

  void _onServerError(Map<String, dynamic> json) {
    final id = json['clientMsgId'] as String?;
    if (id == null) return;
    _timers.remove(id)?.cancel();
    _mutate(id, (x) => x.copyWith(status: MessageStatus.failed));
  }

  Future<void> _onConnected() async {
    // 1) re-send anything still pending (idempotent via clientMsgId)
    for (final list in state.messages.values.toList()) {
      for (final m in list) {
        if (m.status == MessageStatus.sending) _transmit(m);
      }
    }
    // 2) backfill what we missed while offline
    final fetch = _config.fetchSince;
    if (fetch == null) return;
    try {
      final missed = await fetch(_lastServerId());
      for (final m in missed) {
        _upsert(m);
      }
    } catch (_) {
      /* next reconnect will retry */
    }
  }

  // ---------- state helpers ----------

  void _upsert(ChatMessage m) {
    _timers.remove(m.clientMsgId)?.cancel();
    final list = [...?state.messages[m.conversationId]];
    final i = list.indexWhere(
      (x) => x.clientMsgId == m.clientMsgId || (m.id != null && x.id == m.id),
    );
    if (i >= 0) {
      list[i] = m; // echo replaces optimistic bubble in place — no jump
    } else {
      list.add(m);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    _put(m.conversationId, list);
  }

  void _mutate(String clientMsgId, ChatMessage Function(ChatMessage) fn) {
    for (final e in state.messages.entries) {
      final i = e.value.indexWhere((x) => x.clientMsgId == clientMsgId);
      if (i < 0) continue;
      final list = [...e.value];
      list[i] = fn(list[i]);
      _put(e.key, list);
      return;
    }
  }

  void _put(int conversationId, List<ChatMessage> list) {
    state = state.copyWith(messages: {...state.messages, conversationId: list});
  }

  int? _lastServerId() {
    int? last;
    for (final list in state.messages.values) {
      for (final m in list) {
        final id = m.id;
        if (id != null && (last == null || id > last)) last = id;
      }
    }
    return last;
  }

  void _syncConnection() {
    state = state.copyWith(connection: _socket.connection.value);
  }
}
