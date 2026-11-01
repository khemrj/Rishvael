import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

enum ConnState { connecting, connected, disconnected }

typedef JsonMap = Map<String, dynamic>;

class ChatSocket {
  ChatSocket({
    required this.url, // wss://api.yourdomain.com/ws
    required this.getToken, // must return a valid (refreshed if needed) token
    required this.onMessage,
    this.onError,
    this.onConnected, // flush pending + REST backfill here
  });

  final String url;
  final Future<String> Function() getToken;
  final void Function(JsonMap) onMessage;
  final void Function(JsonMap)? onError;
  final VoidCallback? onConnected;

  /// Drives the "Connecting…" banner.
  final ValueNotifier<ConnState> connection = ValueNotifier(
    ConnState.disconnected,
  );

  StompClient? _client;
  Timer? _retry;
  int _attempts = 0;
  bool _wantConnected = false;
  bool _connecting = false;
  bool _disposed = false;

  bool get isConnected => _client?.connected ?? false;
  
  Future<void> connect() async {
    _wantConnected = true;
    if (_connecting || isConnected) return; // no duplicate sockets
    _connecting = true;
    _retry?.cancel();
    _setState(ConnState.connecting);

    try {
      final token = await getToken();
      if (!_wantConnected || _disposed) return;
      _teardown();
    /// create a new client with the fresh token
      late final StompClient client;
      client = StompClient(
        config: StompConfig(
          url: url,
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          connectionTimeout: const Duration(seconds: 10),
          reconnectDelay: Duration.zero, // we reconnect (fresh token)
          heartbeatOutgoing: const Duration(seconds: 10),
          heartbeatIncoming: const Duration(seconds: 10),
          onConnect: (_) {
            if (!identical(client, _client)) return;
            _attempts = 0;
            debugPrint('ChatSocket: WebSocket connected');
            client.subscribe(
              destination: '/user/queue/messages',
              callback: (f) {
                final m = _decode(f.body);
                if (m != null) onMessage(m);
              },
            );
            debugPrint('ChatSocket: subscribed to /user/queue/messages');
            client.subscribe(
              destination: '/user/queue/errors',
              callback: (f) {
                final m = _decode(f.body);
                if (m != null) onError?.call(m);
              },
            );
            debugPrint('ChatSocket: subscribed to /user/queue/errors');
            _setState(ConnState.connected);
            onConnected?.call();
          },
          onStompError: (_) => _drop(client),
          onWebSocketError: (_) => _drop(client),
          onWebSocketDone: () => _drop(client),
          onDisconnect: (_) => _drop(client),
        ),
      );
      _client = client;
      client.activate();
    } catch (_) {
      _setState(ConnState.disconnected);
      _scheduleReconnect(); // token fetch failed, etc.
    } finally {
      _connecting = false;
    }
  }

  /// Returns true if the frame was handed to the socket. If false, the caller
  /// keeps the message pending and re-sends (same clientMsgId) on reconnect.
  bool send({
    required int conversationId,
    required String clientMsgId,
    required String content,
  }) {
    final c = _client;
    if (c == null || !c.connected) return false;
    try {
      c.send(
        destination: '/app/chat.send',
        body: jsonEncode({
          'conversationId': conversationId,
          'clientMsgId': clientMsgId,
          'content': content,
        }),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Call on app resume / network regained.
  void reconnectNow() {
    if (!_wantConnected) return;
    _attempts = 0;
    if (!isConnected) {
      _retry?.cancel();
      connect();
    }
  }

  void disconnect() {
    _wantConnected = false;
    _retry?.cancel();
    _teardown();
    _setState(ConnState.disconnected);
  }

  void dispose() {
    disconnect();
    _disposed = true;
    connection.dispose();
  }

  // ---- internals ----

  /// First failure callback wins; later ones from the same client are ignored
  /// because _client is nulled — so attempts aren't double-counted.
  void _drop(StompClient client) {
    if (!identical(client, _client)) return;
    _client = null;
    client.deactivate();
    _setState(ConnState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_wantConnected || _disposed) return;
    _retry?.cancel();
    final base = min(30, 1 << min(_attempts++, 5));
    final jitterMs = Random().nextInt(500);
    _retry = Timer(Duration(seconds: base, milliseconds: jitterMs), connect);
  }

  void _teardown() {
    final c = _client;
    _client = null;
    c?.deactivate();
  }

  void _setState(ConnState s) {
    if (_disposed || connection.value == s) return;
    connection.value = s;
  }

  JsonMap? _decode(String? body) {
    if (body == null) return null;
    try {
      final v = jsonDecode(body);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }
}