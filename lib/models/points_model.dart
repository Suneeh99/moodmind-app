import 'package:cloud_firestore/cloud_firestore.dart';

enum PointsTransactionType { earned, deducted, bonus }

class PointsTransaction {
  final String id;
  final String userId;
  final int points;
  final PointsTransactionType type;
  final String reason;
  final String? taskId;
  final DateTime createdAt;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.reason,
    this.taskId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'points': points,
      'type': type.toString().split('.').last,
      'reason': reason,
      'taskId': taskId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PointsTransaction.fromMap(Map<String, dynamic> map) {
    return PointsTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      points: map['points'] ?? 0,
      type: PointsTransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => PointsTransactionType.earned,
      ),
      reason: map['reason'] ?? '',
      taskId: map['taskId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class UserPoints {
  final String userId;
  final String userName;
  final String? photoUrl;
  final int totalPoints;
  final int rank;
  final DateTime lastUpdated;

  UserPoints({
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.totalPoints,
    required this.rank,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'photoUrl': photoUrl,
      'totalPoints': totalPoints,
      'rank': rank,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory UserPoints.fromMap(Map<String, dynamic> map) {
    return UserPoints(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      photoUrl: map['photoUrl'],
      totalPoints: map['totalPoints'] ?? 0,
      rank: map['rank'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
