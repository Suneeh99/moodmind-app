// lib/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId; // userId or consultantId
  final String text;
  final DateTime createdAt;
  final List<String> seenBy; // ids who have seen the message
  final bool delivered;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.seenBy,
    required this.delivered,
  });

  factory MessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MessageModel(
      id: doc.id,
      chatId: d['chatId'] as String,
      senderId: d['senderId'] as String,
      text: (d['text'] as String?) ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(d['seenBy'] as List? ?? const []),
      delivered: d['delivered'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'chatId': chatId,
    'senderId': senderId,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
    'seenBy': seenBy,
    'delivered': delivered,
  };
}
