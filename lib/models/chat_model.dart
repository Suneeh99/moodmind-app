// lib/models/chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'consultant_model.dart';

class ChatModel {
  final String id;
  final ConsultantModel consultant;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool hasDoubleCheck;

  ChatModel({
    required this.id,
    required this.consultant,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.hasDoubleCheck,
  });

  /// Build from Firestore chat envelope + your known ConsultantModel
  factory ChatModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    ConsultantModel consultant, {
    required String viewerId,
    required bool viewerIsUser,
  }) {
    final d = doc.data()!;
    final unread = viewerIsUser
        ? (d['unreadCountForUser'] as int? ?? 0)
        : (d['unreadCountForConsultant'] as int? ?? 0);
    final seen = List<String>.from(d['lastMessageSeenBy'] as List? ?? const []);
    final ts = (d['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();

    return ChatModel(
      id: doc.id,
      consultant: consultant,
      lastMessage: (d['lastMessage'] as String?) ?? '',
      lastMessageTime: ts,
      unreadCount: unread,
      hasDoubleCheck: seen.isNotEmpty, // minimal delivered/seen flag
    );
  }
}
