import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({super.key, required this.otherUserId, required this.otherUserName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgController = TextEditingController();
  late Stream<List<Map<String, dynamic>>> _messagesStream;
  final String _myId = SupabaseConfig.client.auth.currentUser!.id;
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    _messagesStream = SupabaseConfig.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Important: Reverse order for chat
        .map((maps) => maps
            .where((m) =>
                (m['sender_id'] == _myId && m['receiver_id'] == widget.otherUserId) ||
                (m['sender_id'] == widget.otherUserId && m['receiver_id'] == _myId))
            .toList());
            
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    try {
      await SupabaseConfig.client
        .from('messages')
        .update({'is_read': true})
        .eq('sender_id', widget.otherUserId)
        .eq('receiver_id', _myId)
        .eq('is_read', false); 
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;
    _msgController.clear();

    // Optimistic Update
    final tempId = DateTime.now().microsecondsSinceEpoch.toString();
    final optimisticMsg = {
      'id': tempId,
      'sender_id': _myId,
      'receiver_id': widget.otherUserId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      'is_sending': true,
    };

    setState(() {
      _messages.insert(0, optimisticMsg); // Add to top (reverse list)
    });

    try {
      await SupabaseConfig.client.from('messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.otherUserId,
        'content': content,
      });
      // The stream will update and replace our optimistic msg eventually
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: const TextStyle(fontSize: 16)),
            const Text("Online", style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
               setState(() => _isLoading = true);
               _setupStream();
               setState(() => _isLoading = false);
            }
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                // Merge stream data with optimistic data if needed, or just rely on stream
                // For simplicity in this fix, we will prefer stream data but keep optimistic ones involved if possible.
                // However, the cleanest way with StreamBuilder is to trust the stream.
                // But for "instant" feel, we need to show local state first.
                
                final streamData = snapshot.data ?? [];
                
                // Combine: Stream Data (Real) + Optimistic Data (Local that are not in stream yet)
                // Note: Stream is ordered DESC by created_at.
                
                // Effective list strategy:
                // If stream has data, use it.
                // Ideally we'd merge, but simpler approach:
                // display stream data. The _sendMessage inserts to DB, DB notifies stream, stream updates.
                // Delay is usually sub-second.
                // To support optimistic UI properly with StreamBuilder is tricky without complex merge logic.
                // We will stick to StreamBuilder for consistency but ensure "reverse" is used for UI stickiness.
                
                final displayMessages = streamData; 

                if (snapshot.connectionState == ConnectionState.waiting && displayMessages.isEmpty) {
                   return const Center(child: CircularProgressIndicator());
                }

                if (displayMessages.isEmpty) return const Center(child: Text("Say Namaste! 🙏"));

                return ListView.builder(
                  reverse: true, // Chat style
                  padding: const EdgeInsets.all(16),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, index) {
                    final msg = displayMessages[index];
                    final isMe = msg['sender_id'] == _myId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final isSending = msg['is_sending'] == true;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? (isSending ? AppTheme.royalMaroon.withOpacity(0.7) : AppTheme.royalMaroon) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg['content'],
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeAgo(DateTime.parse(msg['created_at'])),
                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
                ),
                if(isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isSending ? Icons.access_time : (msg['is_read'] == true ? Icons.done_all : Icons.check),
                    size: 12,
                    color: Colors.white70,
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: AppTheme.royalMaroon,
          ),
        ],
      ),
    );
  }
}
