import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:moodmind_new/models/message_model.dart'; // id, content, timestamp, isFromUser
import 'package:moodmind_new/models/consultant_model.dart';
import 'package:moodmind_new/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ConsultantModel consultant;

  const ChatScreen({Key? key, required this.consultant}) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? _chatId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _ensureChat();
  }

  Future<void> _ensureChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final id = await ChatService.instance.ensureChat(
      userId: user.uid,
      consultantId: widget.consultant.id,
    );

    if (!mounted) return;
    setState(() => _chatId = id);

    await ChatService.instance.markChatSeen(
      chatId: id,
      viewerId: user.uid,
      viewerIsUser: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFFf093fb)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const Icon(Icons.person, color: Colors.white, size: 25),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.consultant.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.consultant.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Messages
            Expanded(
              child: Builder(
                builder: (_) {
                  if (user == null) {
                    return const Center(child: Text('Please log in to chat'));
                  }
                  if (_chatId == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: ChatService.instance.streamMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? const [];
                      final messages = docs.map((d) {
                        final data = d.data();
                        final senderId = data['senderId'] as String? ?? '';
                        final text = data['text'] as String? ?? '';
                        final ts =
                            (data['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                        return MessageModel(
                          id: d.id,
                          chatId: _chatId!,
                          senderId: senderId,
                          text: text,
                          createdAt: ts,
                          seenBy: [],
                          delivered: true,
                        );
                      }).toList();

                      if (messages.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!_scrollController.hasClients) return;
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent + 80,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        });
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(messages[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Composer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFFf093fb)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isMe = message.senderId == _myUid; // <-- I sent this message

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment
                  .end // my messages on the RIGHT
            : MainAxisAlignment.start, // consultant replies on the LEFT
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFFf093fb)],
                      )
                    : null,
                color: isMe ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _chatId == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    await ChatService.instance.sendMessage(
      chatId: _chatId!,
      senderId: user.uid,
      text: text,
      userId: user.uid,
      consultantId: widget.consultant.id,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
