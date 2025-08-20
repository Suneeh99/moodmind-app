import 'package:cloud_firestore/cloud_firestore.dart';

class AlarmSettings {
  final String id;
  final String userId;
  final String ringtone;
  final bool isEnabled;
  final List<int> selectedDays; // 0-6 (Sunday-Saturday)
  final TimeOfDay time;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlarmSettings({
    required this.id,
    required this.userId,
    required this.ringtone,
    required this.isEnabled,
    required this.selectedDays,
    required this.time,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlarmSettings.fromMap(Map<String, dynamic> map) {
    return AlarmSettings(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      ringtone: map['ringtone'] ?? 'Default Alarm',
      isEnabled: map['isEnabled'] ?? false,
      selectedDays: List<int>.from(map['selectedDays'] ?? []),
      time: TimeOfDay(hour: map['hour'] ?? 9, minute: map['minute'] ?? 0),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'ringtone': ringtone,
      'isEnabled': isEnabled,
      'selectedDays': selectedDays,
      'hour': time.hour,
      'minute': time.minute,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AlarmSettings copyWith({
    String? id,
    String? userId,
    String? ringtone,
    bool? isEnabled,
    List<int>? selectedDays,
    TimeOfDay? time,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlarmSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ringtone: ringtone ?? this.ringtone,
      isEnabled: isEnabled ?? this.isEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String format12Hour() {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
