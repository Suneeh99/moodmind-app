import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntryModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime date;
  final DateTime createdAt;
  final Map<String, dynamic> sentimentAnalysis;
  final String dominantEmotion;
  final double confidenceScore;

  DiaryEntryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.date,
    required this.createdAt,
    required this.sentimentAnalysis,
    required this.dominantEmotion,
    required this.confidenceScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'sentimentAnalysis': sentimentAnalysis,
      'dominantEmotion': dominantEmotion,
      'confidenceScore': confidenceScore,
    };
  }

  factory DiaryEntryModel.fromMap(Map<String, dynamic> map) {
    return DiaryEntryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      sentimentAnalysis: Map<String, dynamic>.from(
        map['sentimentAnalysis'] ?? {},
      ),
      dominantEmotion: map['dominantEmotion'] ?? '',
      confidenceScore: (map['confidenceScore'] ?? 0.0).toDouble(),
    );
  }

  DiaryEntryModel copyWith({
    String? title,
    String? content,
    Map<String, dynamic>? sentimentAnalysis,
    String? dominantEmotion,
    double? confidenceScore,
  }) {
    return DiaryEntryModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date,
      createdAt: createdAt,
      sentimentAnalysis: sentimentAnalysis ?? this.sentimentAnalysis,
      dominantEmotion: dominantEmotion ?? this.dominantEmotion,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }
}
