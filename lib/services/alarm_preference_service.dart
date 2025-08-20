import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/firebase_service.dart';

class AlarmPreferenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _usersCollection = 'users';

  // Available alarm options
  static const List<Map<String, String>> alarmOptions = [
    {'id': 'Alarm1', 'name': 'Morning Bell', 'file': 'alarm1.mp3'},
    {'id': 'Alarm2', 'name': 'Gentle Chime', 'file': 'alarm2.mp3'},
    {'id': 'Alarm3', 'name': 'Classic Ring', 'file': 'alarm3.mp3'},
    {'id': 'Alarm4', 'name': 'Soft Melody', 'file': 'alarm4.mp3'},
    {'id': 'Alarm5', 'name': 'Digital Beep', 'file': 'alarm5.mp3'},
    {'id': 'Alarm6', 'name': 'Nature Sound', 'file': 'alarm6.mp3'},
  ];

  // Get current user's selected alarm
  static Future<String> getSelectedAlarm() async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) return 'Alarm1'; // Default

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['preferences']?['selectedAlarm'] ?? 'Alarm1';
      }
      return 'Alarm1';
    } catch (e) {
      print('Error getting selected alarm: $e');
      return 'Alarm1';
    }
  }

  // Save selected alarm preference
  static Future<bool> saveSelectedAlarm(String alarmId) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw 'User not authenticated';

      await _firestore.collection(_usersCollection).doc(userId).update({
        'preferences.selectedAlarm': alarmId,
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      print('Selected alarm saved: $alarmId');
      return true;
    } catch (e) {
      print('Error saving selected alarm: $e');
      return false;
    }
  }

  // Preview alarm sound
  static Future<void> previewAlarm(String alarmId) async {
    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Find the alarm file
      final alarm = alarmOptions.firstWhere(
        (alarm) => alarm['id'] == alarmId,
        orElse: () => alarmOptions.first,
      );

      // Play the alarm sound
      await _audioPlayer.play(AssetSource('sounds/${alarm['file']}'));

      print('Playing preview: ${alarm['name']}');
    } catch (e) {
      print('Error playing alarm preview: $e');
    }
  }

  // Stop preview
  static Future<void> stopPreview() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping preview: $e');
    }
  }

  // Get alarm name by ID
  static String getAlarmName(String alarmId) {
    final alarm = alarmOptions.firstWhere(
      (alarm) => alarm['id'] == alarmId,
      orElse: () => alarmOptions.first,
    );
    return alarm['name']!;
  }

  // Dispose audio player
  static void dispose() {
    _audioPlayer.dispose();
  }
}
