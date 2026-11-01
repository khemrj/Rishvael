import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/controller/chat_controller.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/errrors/friendly_message.dart';
import 'package:flutter_application_1/core/responsive.dart';
import 'package:flutter_application_1/models/chat_message.dart';
import 'package:flutter_application_1/providers/chat_config_provider.dart';
import 'package:flutter_application_1/socket/chat_socket.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// THEME
// ---------------------------------------------------------------------------

class _Palette {
  _Palette(bool dark)
      : wallpaper = dark ? const Color(0xFF0B141A) : const Color(0xFFEFE7DE),
        outgoing = dark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3),
        incoming = dark ? const Color(0xFF202C33) : Colors.white,
        text = dark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21),
        meta = dark ? const Color(0xFF8696A0) : const Color(0xFF667781),
        bar = dark ? const Color(0xFF202C33) : const Color(0xFF008069),
        input = dark ? const Color(0xFF202C33) : Colors.white,
        chip = dark ? const Color(0xFF182229) : Colors.white;

  final Color wallpaper, outgoing, incoming, text, meta, bar, input, chip;

  static const accent = Color(0xFF00A884);
  static const danger = Color(0xFFE53935);
  static const readTick = Color(0xFF53BDEB);
}

// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLabel(DateTime d) {
  final now = DateTime.now();
  if (_sameDay(d, now)) return 'Today';
  if (_sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _hm(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} '
      '${d.hour < 12 ? 'AM' : 'PM'}';
}

String _initialOf(String name) =>
    name.isEmpty ? '?' : name[0].toUpperCase();

// ---------------------------------------------------------------------------
// HISTORY MODEL
// Matches GET /api/chat/conversations/{id}/messages:
// { "messages": [...], "hasMore": bool, "oldestId": int }
// ---------------------------------------------------------------------------

class _HistoryPage {
  const _HistoryPage({
    required this.messages,
    required this.hasMore,
    this.oldestId,
  });

  final List<ChatMessage> messages; // sorted oldest -> newest
  final bool hasMore;
  final int? oldestId;

  factory _HistoryPage.fromJson(Map<String, dynamic> json) {
    final raw = (json['messages'] as List?) ?? const [];
    final messages = raw
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return _HistoryPage(
      messages: messages,
      hasMore: json['hasMore'] as bool? ?? false,
      oldestId: (json['oldestId'] as num?)?.toInt(),
    );
  }
}

enum _LoadStatus { loading, ready, error }

// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final int conversationId;
  final String title;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();

  bool _hasText = false;
  bool _showJumpToLatest = false;

  // Server history, loaded when the screen opens.
  List<ChatMessage> _history = const [];
  _LoadStatus _historyStatus = _LoadStatus.loading;
  String? _historyError;
  bool _hasMoreHistory = false;
  bool _loadingOlder = false;
  int? _oldestLoadedId;

  // -------------------------------------------------------------------------
  // LIFECYCLE
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _text.addListener(_onTextChanged);
    _scroll.addListener(_onScroll);
    _loadInitialHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(chatControllerProvider.notifier).onResume();
    }
  }

  // -------------------------------------------------------------------------
  // HISTORY LOADING
  // -------------------------------------------------------------------------

  Future<_HistoryPage> _fetchHistoryPage({int? beforeId}) async {
    final query = <String, dynamic>{};
    if (beforeId != null) query['beforeId'] = beforeId;

    final response = await ApiClient.dio.get<Map<String, dynamic>>(
      '/api/chat/conversations/${widget.conversationId}/messages',
      queryParameters: query.isEmpty ? null : query,
      options: ApiClient.strict,
    );

    final body = response.data;
    if (body == null) {
      throw const FormatException('Empty message history response');
    }
    return _HistoryPage.fromJson(body);
  }

  Future<void> _loadInitialHistory() async {
    try {
      final page = await _fetchHistoryPage();
      if (!mounted) return;
      setState(() {
        _history = page.messages;
        _hasMoreHistory = page.hasMore;
        _oldestLoadedId = page.oldestId;
        _historyStatus = _LoadStatus.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = friendlyMessage(e);
        _historyStatus = _LoadStatus.error;
      });
    }
  }

  void _retryInitialHistory() {
    setState(() {
      _historyStatus = _LoadStatus.loading;
      _historyError = null;
    });
    _loadInitialHistory();
  }

  Future<void> _loadOlderHistory() async {
    if (_loadingOlder || !_hasMoreHistory || _oldestLoadedId == null) return;

    setState(() => _loadingOlder = true);
    try {
      final page = await _fetchHistoryPage(beforeId: _oldestLoadedId);
      if (!mounted) return;
      setState(() {
        // Older page goes in front; the list stays oldest -> newest.
        _history = [...page.messages, ..._history];
        _hasMoreHistory = page.hasMore;
        _oldestLoadedId = page.oldestId ?? _oldestLoadedId;
      });
    } catch (e) {
      if (mounted) _showSnack(friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  /// Live socket messages and REST history can overlap (the echo of a message
  /// you just sent may already be in history). De-duplicate by server id and
  /// by clientMsgId, then sort by time.
  List<ChatMessage> _combineHistoryWithLive(List<ChatMessage> live) {
    final serverIds = {for (final m in _history) if (m.id != null) m.id!};
    final serverClientIds = {for (final m in _history) m.clientMsgId};

    final fresh = live.where(
      (m) =>
          !serverClientIds.contains(m.clientMsgId) &&
          !(m.id != null && serverIds.contains(m.id)),
    );

    return [..._history, ...fresh]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // -------------------------------------------------------------------------
  // INPUT & SCROLL
  // -------------------------------------------------------------------------

  void _onTextChanged() {
    final has = _text.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;

    // Reversed list: the top of the screen is the far end (oldest messages).
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadOlderHistory();
    }

    final showJump = pos.pixels > 320;
    if (showJump != _showJumpToLatest) {
      setState(() => _showJumpToLatest = showJump);
    }
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(chatControllerProvider.notifier).send(widget.conversationId, text);
    _text.clear();
    _jumpToLatest();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = _Palette(Theme.of(context).brightness == Brightness.dark);
    final chatConfig = ref.watch(chatConfigProvider);

    if (chatConfig == null) {
      return _UnconfiguredView(title: widget.title, p: p);
    }

    final conn = ref.watch(chatControllerProvider.select((s) => s.connection));
    final live = ref.watch(
      chatControllerProvider.select(
        (s) => s.messages[widget.conversationId] ?? const <ChatMessage>[],
      ),
    );

    // Oldest -> newest in the data; reversed so index 0 is the newest,
    // which is what a reversed ListView expects.
    final items = _combineHistoryWithLive(live).reversed.toList();

    return Scaffold(
      backgroundColor: p.wallpaper,
      appBar: _buildAppBar(p, conn),
      body: Column(
        children: [
          if (conn != ConnState.connected) _ConnectionBanner(conn: conn),
          Expanded(
            child: _buildMessageArea(items, chatConfig.currentUserId, p),
          ),
          _buildComposer(p),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(_Palette p, ConnState conn) {
    final subtitle = switch (conn) {
      ConnState.connected => 'Connected',
      ConnState.connecting => 'Connecting…',
      ConnState.disconnected => 'Offline',
    };

    return AppBar(
      backgroundColor: p.bar,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Text(
              _initialOf(widget.title),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageArea(List<ChatMessage> items, int me, _Palette p) {
    if (items.isEmpty) {
      return switch (_historyStatus) {
        _LoadStatus.loading => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        _LoadStatus.error => _HistoryErrorView(
            message: _historyError ?? 'Could not load messages.',
            onRetry: _retryInitialHistory,
            p: p,
          ),
        _LoadStatus.ready => _EmptyChatView(p: p),
      };
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          itemCount: items.length,
          itemBuilder: (context, i) => _buildRow(context, items, i, me, p),
        ),
        if (_loadingOlder)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(child: _OlderLoader(p: p)),
          ),
        if (_showJumpToLatest)
          Positioned(
            right: 12,
            bottom: 12,
            child: _JumpToLatestButton(p: p, onTap: _jumpToLatest),
          ),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    List<ChatMessage> items,
    int i,
    int me,
    _Palette p,
  ) {
    final m = items[i];
    final older = i + 1 < items.length ? items[i + 1] : null;

    final isMine = m.senderId == me;
    final newDay = older == null || !_sameDay(older.createdAt, m.createdAt);
    final firstInGroup = newDay || older?.senderId != m.senderId;

    final maxBubbleWidth =
        math.min(context.windowSize.width * 0.78, 520.0);

    return Column(
      key: ValueKey(m.clientMsgId),
      children: [
        if (newDay) _DayChip(label: _dayLabel(m.createdAt), p: p),
        Padding(
          padding: EdgeInsets.only(top: firstInGroup ? 8 : 2),
          child: _PopIn(
            enabled: isMine,
            createdAt: m.createdAt,
            child: Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                child: _Bubble(
                  msg: m,
                  isMine: isMine,
                  tail: firstInGroup,
                  p: p,
                  onRetry: () =>
                      ref.read(chatControllerProvider.notifier).retry(m),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComposer(_Palette p) {
    return SafeArea(
      top: false,
      child: Container(
        color: p.wallpaper,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: p.input,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: p.text, fontSize: 16),
                  cursorColor: _Palette.accent,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: p.meta),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedScale(
              scale: _hasText ? 1 : 0.9,
              duration: const Duration(milliseconds: 150),
              child: Material(
                color: _hasText
                    ? _Palette.accent
                    : _Palette.accent.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _hasText ? _send : null,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATES
// ---------------------------------------------------------------------------

class _UnconfiguredView extends StatelessWidget {
  const _UnconfiguredView({required this.title, required this.p});

  final String title;
  final _Palette p;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: p.bar,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: p.meta, size: 40),
              const SizedBox(height: 12),
              Text(
                'Chat is not configured yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView({required this.p});

  final _Palette p;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: _Palette.accent,
            ),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: TextStyle(
                color: p.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Send a message to start the conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.meta, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryErrorView extends StatelessWidget {
  const _HistoryErrorView({
    required this.message,
    required this.onRetry,
    required this.p,
  });

  final String message;
  final VoidCallback onRetry;
  final _Palette p;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: p.meta),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.text, fontSize: 15),
            ),
            const SizedBox(height: 16),
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
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.conn});

  final ConnState conn;

  @override
  Widget build(BuildContext context) {
    final offline = conn == ConnState.disconnected;

    return Container(
      width: double.infinity,
      color: offline ? const Color(0xFFFDE7E9) : const Color(0xFFFFF3C4),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!offline) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              offline
                  ? 'Offline. Messages will send when you reconnect.'
                  : 'Connecting…',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: offline
                    ? const Color(0xFF8A1C1C)
                    : const Color(0xFF6B5B00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OlderLoader extends StatelessWidget {
  const _OlderLoader({required this.p});

  final _Palette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.chip,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4),
        ],
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({required this.p, required this.onTap});

  final _Palette p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.chip,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.keyboard_arrow_down_rounded, color: p.text),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MESSAGE PIECES
// ---------------------------------------------------------------------------

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.msg,
    required this.isMine,
    required this.tail,
    required this.p,
    required this.onRetry,
  });

  final ChatMessage msg;
  final bool isMine, tail;
  final _Palette p;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(12);
    const small = Radius.circular(2);
    final radius = BorderRadius.only(
      topLeft: (!isMine && tail) ? small : r,
      topRight: (isMine && tail) ? small : r,
      bottomLeft: r,
      bottomRight: r,
    );

    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
      decoration: BoxDecoration(
        color: isMine ? p.outgoing : p.incoming,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Invisible spacer keeps the last line clear of the time and ticks.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: msg.content),
                WidgetSpan(
                  child: SizedBox(width: isMine ? 74 : 56, height: 14),
                ),
              ],
            ),
            style: TextStyle(color: p.text, fontSize: 16, height: 1.25),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hm(msg.createdAt),
                  style: TextStyle(color: p.meta, fontSize: 11),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: msg.status, color: p.meta),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        if (isMine && msg.status == MessageStatus.sending)
          const _SendingCaption(),
        if (isMine && msg.status == MessageStatus.failed)
          GestureDetector(
            onTap: onRetry,
            child: const Padding(
              padding: EdgeInsets.only(top: 3, right: 4),
              child: Text(
                'Not sent · Tap to retry',
                style: TextStyle(
                  fontSize: 11,
                  color: _Palette.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.color});

  final MessageStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      MessageStatus.sending => Icons.access_time_rounded,
      MessageStatus.sent => Icons.done_rounded,
      MessageStatus.failed => Icons.error_outline_rounded,
    };

    final iconColor = switch (status) {
      MessageStatus.failed => _Palette.danger,
      MessageStatus.sent => _Palette.readTick,
      MessageStatus.sending => color,
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: Icon(
        icon,
        key: ValueKey(status),
        size: 14,
        color: iconColor,
      ),
    );
  }
}

/// "Sending…" fades in only if the ack is slow (over 700ms), so fast sends
/// never flash a label.
class _SendingCaption extends StatefulWidget {
  const _SendingCaption();

  @override
  State<_SendingCaption> createState() => _SendingCaptionState();
}

class _SendingCaptionState extends State<_SendingCaption> {
  bool _show = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _show ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: const Padding(
        padding: EdgeInsets.only(top: 3, right: 4),
        child: Text(
          'Sending…',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Color(0xFF8696A0),
          ),
        ),
      ),
    );
  }
}

/// Slide and fade for freshly sent messages only. History never re-animates.
class _PopIn extends StatefulWidget {
  const _PopIn({
    required this.enabled,
    required this.createdAt,
    required this.child,
  });

  final bool enabled;
  final DateTime createdAt;
  final Widget child;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final isFresh = widget.enabled &&
        DateTime.now().difference(widget.createdAt).inMilliseconds.abs() <
            1500;
    if (isFresh) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _animation.value)),
          child: child,
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.p});

  final String label;
  final _Palette p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: p.chip,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: TextStyle(color: p.meta, fontSize: 12)),
        ),
      ),
    );
  }
}