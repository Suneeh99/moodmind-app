import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences,
  });

  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'preferences': preferences ?? {},
    };
  }

  // Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: _parseDateTime(map['createdAt']),
      lastLoginAt: _parseDateTime(map['lastLoginAt']),
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now();
    }
    if (dateTime is Timestamp) {
      return dateTime.toDate();
    }
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        print('Error parsing date string: $dateTime');
        return DateTime.now();
      }
    }
    if (dateTime is DateTime) {
      return dateTime;
    }
    // Fallback
    return DateTime.now();
  }

  // Copy with method for updates
  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }

  // Convenience getters for alarm preferences
  String get selectedAlarm => preferences?['selectedAlarm'] ?? 'Alarm1';
  bool get alarmEnabled => preferences?['alarmEnabled'] ?? true;
  List<int> get alarmDays =>
      List<int>.from(preferences?['alarmDays'] ?? [1, 2, 3, 4, 5]);
  int get alarmHour => preferences?['alarmHour'] ?? 9;
  int get alarmMinute => preferences?['alarmMinute'] ?? 0;

  // Helper method to update alarm preferences
  UserModel updateAlarmPreferences({
    String? selectedAlarm,
    bool? alarmEnabled,
    List<int>? alarmDays,
    int? alarmHour,
    int? alarmMinute,
  }) {
    final currentPrefs = Map<String, dynamic>.from(preferences ?? {});

    if (selectedAlarm != null) currentPrefs['selectedAlarm'] = selectedAlarm;
    if (alarmEnabled != null) currentPrefs['alarmEnabled'] = alarmEnabled;
    if (alarmDays != null) currentPrefs['alarmDays'] = alarmDays;
    if (alarmHour != null) currentPrefs['alarmHour'] = alarmHour;
    if (alarmMinute != null) currentPrefs['alarmMinute'] = alarmMinute;

    return copyWith(preferences: currentPrefs, lastLoginAt: DateTime.now());
  }

  // Convert to JSON string for debugging
  @override
  String toString() {
    return 'UserModel{uid: $uid, name: $name, email: $email, photoUrl: $photoUrl, createdAt: $createdAt, lastLoginAt: $lastLoginAt, preferences: $preferences}';
  }
}
