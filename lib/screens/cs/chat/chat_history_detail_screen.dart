import 'package:flutter/material.dart';
import 'package:tkbank/models/chat_history_message.dart';
import 'package:tkbank/services/cs/chat/chat_api_service.dart';

class ChatHistoryDetailScreen extends StatefulWidget {
  final ChatApiService api;
  final int sessionId;
  final String title;

  const ChatHistoryDetailScreen({
    super.key,
    required this.api,
    required this.sessionId,
    required this.title,
  });

  @override
  State<ChatHistoryDetailScreen> createState() => _ChatHistoryDetailScreenState();
}

class _ChatHistoryDetailScreenState extends State<ChatHistoryDetailScreen> {
  final _scroll = ScrollController();

  final List<ChatHistoryMessage> _items = [];
  String? _cursor;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load(first: true);

    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool first = false}) async {
    if (_loading) return;
    if (!first && !_hasMore) return;

    setState(() => _loading = true);
    try {
      final page = await widget.api.fetchChatHistoryMessages(
        sessionId: widget.sessionId,
        cursor: first ? null : _cursor,
        size: 50,
      );

      setState(() {
        if (first) _items.clear();
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _hasMore = page.nextCursor != null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지를 불러오지 못했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _bubble(ChatHistoryMessage m) {
    final st = m.senderType.toUpperCase();

    if (st == 'SYSTEM') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(m.message, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ),
      );
    }

    final isMe = st == 'USER';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.pink.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isMe
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Text(m.message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: const Color(0xfff7f7f7),
      body: RefreshIndicator(
        onRefresh: () => _load(first: true),
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          itemCount: _items.length + 1,
          itemBuilder: (ctx, i) {
            if (i == _items.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : (!_hasMore ? const Text('마지막 메시지입니다.') : const SizedBox.shrink()),
                ),
              );
            }
            return _bubble(_items[i]);
          },
        ),
      ),
    );
  }
}
