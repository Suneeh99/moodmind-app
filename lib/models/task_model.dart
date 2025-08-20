import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskStatus { pending, completed, failed, overdue }

class Task {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final TimeOfDay time;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? verificationPhotoUrl;
  final int pointsAwarded;
  final bool requiresVerification;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.time,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.verificationPhotoUrl,
    this.pointsAwarded = 0,
    this.requiresVerification = true,
  });

  DateTime get scheduledDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String get timeString {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;
  bool get isFailed => status == TaskStatus.failed;
  bool get isOverdue => status == TaskStatus.overdue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'verificationPhotoUrl': verificationPhotoUrl,
      'pointsAwarded': pointsAwarded,
      'requiresVerification': requiresVerification,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: TimeOfDay(
        hour: map['timeHour'] ?? 0,
        minute: map['timeMinute'] ?? 0,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      verificationPhotoUrl: map['verificationPhotoUrl'],
      pointsAwarded: map['pointsAwarded'] ?? 0,
      requiresVerification: map['requiresVerification'] ?? true,
    );
  }

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    TimeOfDay? time,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? verificationPhotoUrl,
    int? pointsAwarded,
    bool? requiresVerification,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      verificationPhotoUrl: verificationPhotoUrl ?? this.verificationPhotoUrl,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      requiresVerification: requiresVerification ?? this.requiresVerification,
    );
  }
}
