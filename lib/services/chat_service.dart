// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  ChatService._();
  static final instance = ChatService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  /// Ensure a chat exists between a user and a consultant. Returns chatId.
  Future<String> ensureChat({
    required String userId,
    required String consultantId,
  }) async {
    final q = await _chats
        .where('userId', isEqualTo: userId)
        .where('consultantId', isEqualTo: consultantId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return q.docs.first.id;

    final ref = await _chats.add({
      'participants': [userId, consultantId],
      'userId': userId,
      'consultantId': consultantId,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': null,
      'unreadCountForUser': 0,
      'unreadCountForConsultant': 0,
      'lastMessageSeenBy': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Stream list of chats for a given user (as the viewer).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserChats(String userId) {
    return _chats
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Stream messages for a given chat.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String chatId) {
    return _messages(
      chatId,
    ).orderBy('createdAt', descending: false).snapshots();
  }

  /// Send message and update envelope/unreads atomically.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String userId,
    required String consultantId,
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    final msgRef = _messages(chatId).doc();

    batch.set(msgRef, {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'createdAt': now,
      'seenBy': [senderId],
      'delivered': true,
    });

    final chatRef = _chats.doc(chatId);
    final isUserSender = senderId == userId;

    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': now,
      'lastSenderId': senderId,
      'updatedAt': now,
      if (isUserSender)
        'unreadCountForConsultant': FieldValue.increment(1)
      else
        'unreadCountForUser': FieldValue.increment(1),
      'lastMessageSeenBy': [senderId],
    });

    await batch.commit();
  }

  /// Mark chat as seen by `viewerId` and zero their unread counter.
  Future<void> markChatSeen({
    required String chatId,
    required String viewerId,
    required bool viewerIsUser,
  }) async {
    final chatRef = _chats.doc(chatId);

    await chatRef.update({
      viewerIsUser ? 'unreadCountForUser' : 'unreadCountForConsultant': 0,
      'lastMessageSeenBy': FieldValue.arrayUnion([viewerId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Mark recent messages as seen (best-effort last 50)
    final recent = await _messages(
      chatId,
    ).orderBy('createdAt', descending: true).limit(50).get();

    final batch = _db.batch();
    for (final d in recent.docs) {
      final seenBy = List<String>.from(d.data()['seenBy'] ?? const []);
      if (!seenBy.contains(viewerId)) {
        batch.update(d.reference, {
          'seenBy': FieldValue.arrayUnion([viewerId]),
        });
      }
    }
    await batch.commit();
  }

  /// Convenience: create chat if needed and send first message.
  Future<String> startChatAndSend({
    required String userId,
    required String consultantId,
    required String text,
  }) async {
    final chatId = await ensureChat(userId: userId, consultantId: consultantId);
    await sendMessage(
      chatId: chatId,
      senderId: userId,
      text: text,
      userId: userId,
      consultantId: consultantId,
    );
    return chatId;
  }
}
