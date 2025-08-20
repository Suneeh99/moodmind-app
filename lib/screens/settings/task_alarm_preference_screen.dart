import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/alarm_preference_service.dart';

class TaskAlarmPreferenceScreen extends StatefulWidget {
  const TaskAlarmPreferenceScreen({Key? key}) : super(key: key);

  @override
  State<TaskAlarmPreferenceScreen> createState() =>
      _TaskAlarmPreferenceScreenState();
}

class _TaskAlarmPreferenceScreenState extends State<TaskAlarmPreferenceScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String _selectedAlarm = 'Alarm1';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _currentlyPlaying;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _loadSelectedAlarm();
  }

  Future<void> _loadSelectedAlarm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final selectedAlarm = await AlarmPreferenceService.getSelectedAlarm();
      setState(() {
        _selectedAlarm = selectedAlarm;
      });
    } catch (e) {
      print('Error loading selected alarm: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _previewAlarm(String alarmId) async {
    // Stop current preview if playing
    if (_currentlyPlaying != null) {
      await AlarmPreferenceService.stopPreview();
    }

    setState(() {
      _currentlyPlaying = alarmId;
    });

    await AlarmPreferenceService.previewAlarm(alarmId);

    // Auto-stop after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentlyPlaying == alarmId) {
        _stopPreview();
      }
    });
  }

  Future<void> _stopPreview() async {
    await AlarmPreferenceService.stopPreview();
    setState(() {
      _currentlyPlaying = null;
    });
  }

  Future<void> _saveAlarmPreference() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await AlarmPreferenceService.saveSelectedAlarm(
        _selectedAlarm,
      );

      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Alarm preference saved: ${AlarmPreferenceService.getAlarmName(_selectedAlarm)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save alarm preference'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving alarm preference'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 450),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isSaving
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Saving alarm preference...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      const Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Task Reminder Sound',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Choose your preferred alarm sound for task reminders. Tap to preview each sound.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Alarm Options
                      Expanded(
                        child: ListView.builder(
                          itemCount: AlarmPreferenceService.alarmOptions.length,
                          itemBuilder: (context, index) {
                            final alarm =
                                AlarmPreferenceService.alarmOptions[index];
                            final alarmId = alarm['id']!;
                            final alarmName = alarm['name']!;
                            final isSelected = _selectedAlarm == alarmId;
                            final isPlaying = _currentlyPlaying == alarmId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.volume_up
                                        : Icons.music_note,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  alarmName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  alarmId,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Preview Button
                                    IconButton(
                                      onPressed: () => isPlaying
                                          ? _stopPreview()
                                          : _previewAlarm(alarmId),
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      tooltip: isPlaying ? 'Stop' : 'Preview',
                                    ),
                                    // Selection Indicator
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.primaryBlue,
                                        size: 24,
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedAlarm = alarmId;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Current Selection Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Selected: ${AlarmPreferenceService.getAlarmName(_selectedAlarm)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _stopPreview();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: Colors.grey.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveAlarmPreference,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopPreview();
    _animationController.dispose();
    super.dispose();
  }
}
