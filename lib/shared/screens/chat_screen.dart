import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

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
  final List<Map<String, dynamic>> _pendingMessages = []; 

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    // Re-creating the stream forces a fresh fetch from Supabase
    _messagesStream = SupabaseConfig.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps
            .where((m) =>
                (m['sender_id'] == _myId && m['receiver_id'] == widget.otherUserId) ||
                (m['sender_id'] == widget.otherUserId && m['receiver_id'] == _myId))
            .toList());
            
    _markAsRead();
  }

  void _forceRefresh() {
    if(!mounted) return;
    setState(() {
      _setupStream();
    });
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

  Future<void> _sendMessage({String? customContent}) async {
    final content = customContent ?? _msgController.text.trim();
    if (content.isEmpty) return;
    
    if (customContent == null) _msgController.clear(); // Clear input if it's a normal msg

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
      _pendingMessages.insert(0, optimisticMsg);
    });

    try {
      await SupabaseConfig.client.from('messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.otherUserId,
        'content': content,
      });

      // Force refresh after a short delay to ensure "Realtime" feel even if subscription is broken
      await Future.delayed(const Duration(milliseconds: 800));
      _forceRefresh();
      
      // We also clean up the specific pending message after refresh gives us the real one
      // But purely for safety, we can just clear matching pending messages
      if(mounted) {
         setState(() {
            _pendingMessages.removeWhere((m) => m['id'] == tempId);
         });
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
        setState(() => _pendingMessages.removeWhere((m) => m['id'] == tempId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Cleaner grey
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(Constants.avatarPlaceholder),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Online", style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: "Mark Resolved",
            onPressed: () {
               _sendMessage(customContent: "✅ This issue has been marked as resolved.");
            },
          ),
        ],
        backgroundColor: AppTheme.royalMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                final streamData = snapshot.data ?? [];
                
                // Merge logic: Show pending unless exact match found in stream
                final displayPending = _pendingMessages.where((pending) {
                   final isDuplicate = streamData.any((real) => 
                      real['sender_id'] == _myId && 
                      real['content'] == pending['content'] &&
                      DateTime.parse(real['created_at']).difference(DateTime.parse(pending['created_at'])).inMinutes.abs() < 1
                   );
                   return !isDuplicate;
                }).toList();

                final allMessages = [...displayPending, ...streamData];

                if (snapshot.connectionState == ConnectionState.waiting && allMessages.isEmpty) {
                   return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final msg = allMessages[index];
                    final isMe = msg['sender_id'] == _myId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final isSending = msg['is_sending'] == true;
    final isSystemMsg = msg['content'].toString().startsWith("✅");
    final time = TimeOfDay.fromDateTime(DateTime.parse(msg['created_at'])).format(context);

    if (isSystemMsg) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Text(msg['content'], style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isMe 
              ? LinearGradient(colors: [AppTheme.royalMaroon, AppTheme.royalMaroon.withOpacity(0.85)]) 
              : const LinearGradient(colors: [Colors.white, Colors.white]),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 3, offset: const Offset(0, 1))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 20), // Space for time
                child: Text(
                  msg['content'],
                  style: TextStyle(
                    fontSize: 15, 
                    color: isMe ? Colors.white : Colors.black87,
                    height: 1.3
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                      time,
                      style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey[500]),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isSending ? Icons.access_time : (msg['is_read'] == true ? Icons.done_all : Icons.check),
                        size: 14,
                        color: isSending ? Colors.white60 : (msg['is_read'] == true ? Colors.lightBlueAccent : Colors.white60),
                      ),
                    ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 5)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: () {}, 
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.royalMaroon,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
