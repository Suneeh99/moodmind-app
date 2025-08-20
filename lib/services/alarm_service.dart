import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _alarmTimer;
  Timer? _timeoutTimer;
  
  final StreamController<Task> _alarmStreamController = 
      StreamController<Task>.broadcast();
  
  Stream<Task> get alarmStream => _alarmStreamController.stream;

  Future<void> playAlarm(Task task, UserModel user) async {
    try {
      // Stop any existing alarm
      await stopAlarm();

      // Get user's selected alarm sound
      final alarmSound = user.selectedAlarm;
      final soundPath = 'sounds/$alarmSound.mp3';

      // Play alarm sound
      await _audioPlayer.play(AssetSource(soundPath));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Vibrate device
      HapticFeedback.vibrate();

      // Emit alarm event
      _alarmStreamController.add(task);

      // Set timeout for 30 seconds
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        stopAlarm();
        // Show verification screen
        _showVerificationRequired(task);
      });

    } catch (e) {
      print('Error playing alarm: $e');
    }
  }

  Future<void> stopAlarm() async {
    try {
      await _audioPlayer.stop();
      _alarmTimer?.cancel();
      _timeoutTimer?.cancel();
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }

  void _showVerificationRequired(Task task) {
    // This will be handled by the UI layer
    _alarmStreamController.add(task);
  }

  void dispose() {
    _audioPlayer.dispose();
    _alarmTimer?.cancel();
    _timeoutTimer?.cancel();
    _alarmStreamController.close();
  }
}
