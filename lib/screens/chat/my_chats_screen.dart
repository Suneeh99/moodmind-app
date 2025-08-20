import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:moodmind_new/screens/chat/consultants_list_screen.dart';
import '../../utils/app_theme.dart';
import '../../models/chat_model.dart';
import '../../models/consultant_model.dart';
import 'chat_screen.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  MyChatsScreenState createState() => MyChatsScreenState();
}

class MyChatsScreenState extends State<MyChatsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final _consultantCache = <String, ConsultantModel>{};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
        actions: [
          IconButton(
            tooltip: 'Find Consultants',
            icon: const Icon(Icons.person_search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConsultantListScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: userId == null
            ? const Center(child: Text('Please log in to view chats'))
            : FadeTransition(
                opacity: _fadeAnimation,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('userId', isEqualTo: userId)
                      .orderBy('lastMessageTime', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return _emptyState(context);
                    }

                    final chatDocs = snap.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: chatDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final d = chatDocs[index];
                        final data = d.data();
                        final consultantId =
                            data['consultantId'] as String? ?? '';

                        // Badge counts & envelope state
                        final unreadCount =
                            (data['unreadCountForUser'] as int?) ?? 0;
                        final lastMessage =
                            (data['lastMessage'] as String?) ?? '';
                        final lastMessageTime =
                            (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                        final seenBy = List<String>.from(
                          data['lastMessageSeenBy'] as List? ?? const [],
                        );
                        final hasDoubleCheck = seenBy.isNotEmpty;

                        return FutureBuilder<ConsultantModel>(
                          future: _getConsultant(consultantId),
                          builder: (context, consSnap) {
                            if (!consSnap.hasData) {
                              return _chatTileSkeleton();
                            }
                            final consultant = consSnap.data!;
                            // Hydrate your ChatModel so your existing tile UI can stay the same
                            final chat = ChatModel(
                              id: d.id,
                              consultant: consultant,
                              lastMessage: lastMessage,
                              lastMessageTime: lastMessageTime,
                              unreadCount: unreadCount,
                              hasDoubleCheck: hasDoubleCheck,
                            );

                            return _ChatListTile(
                              chat: chat,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatScreen(consultant: consultant),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  /// Lazy fetch a consultant profile and cache it for later uses.
  Future<ConsultantModel> _getConsultant(String consultantId) async {
    if (_consultantCache.containsKey(consultantId)) {
      return _consultantCache[consultantId]!;
    }
    final doc = await FirebaseFirestore.instance
        .collection('consultants')
        .doc(consultantId)
        .get();

    final data = doc.data() ?? <String, dynamic>{};
    final model = ConsultantModel(
      id: consultantId,
      displayName: (data['displayName'] as String?) ?? 'Consultant',
      email: (data['email'] as String?) ?? 'Counseling',
    );

    _consultantCache[consultantId] = model;
    return model;
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 56),
            const SizedBox(height: 12),
            const Text(
              'No chats yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find a consultant to start a conversation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.person_search_rounded),
              label: const Text('Find Consultants'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConsultantListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatTileSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 140, color: Colors.black12),
                const SizedBox(height: 8),
                Container(height: 12, width: 220, color: Colors.black12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(height: 12, width: 24, color: Colors.black12),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// A list tile that mirrors your existing chat row UI without changing visuals.
/// It simply binds to ChatModel values populated from Firestore.
class _ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const _ChatListTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final consultant = chat.consultant;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              children: [
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TitleSubtitle(
                name: consultant.displayName,
                specialization: consultant.email,
                lastMessage: chat.lastMessage,
                hasDoubleCheck: chat.hasDoubleCheck,
              ),
            ),
            const SizedBox(width: 8),
            _TrailingMeta(
              time: chat.lastMessageTime,
              unread: chat.unreadCount,
              formatTime: (t) =>
                  (context
                      .findAncestorStateOfType<MyChatsScreenState>()
                      ?._formatTime(t)) ??
                  '',
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleSubtitle extends StatelessWidget {
  final String name;
  final String specialization;
  final String lastMessage;
  final bool hasDoubleCheck;

  const _TitleSubtitle({
    required this.name,
    required this.specialization,
    required this.lastMessage,
    required this.hasDoubleCheck,
  });

  @override
  Widget build(BuildContext context) {
    final grey600 = Colors.grey.shade600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          specialization,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: grey600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (hasDoubleCheck)
              const Icon(
                Icons.done_all_rounded,
                size: 18,
                color: Colors.blueAccent,
              ),
            if (hasDoubleCheck) const SizedBox(width: 4),
            Expanded(
              child: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: grey600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrailingMeta extends StatelessWidget {
  final DateTime time;
  final int unread;
  final String Function(DateTime) formatTime;

  const _TrailingMeta({
    required this.time,
    required this.unread,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatTime(time),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              unread > 99 ? '99+' : '$unread',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          const SizedBox(height: 18),
      ],
    );
  }
}
