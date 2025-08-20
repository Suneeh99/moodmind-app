// lib/widgets/task_verification_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/points_service.dart';
import '../utils/app_theme.dart';
import '../services/enhanced_ai_service.dart';

class TaskVerificationDialog extends StatefulWidget {
  final Task task;
  final Function(bool verified, int points) onVerificationComplete;

  const TaskVerificationDialog({
    Key? key,
    required this.task,
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<TaskVerificationDialog> createState() => _TaskVerificationDialogState();
}

class _TaskVerificationDialogState extends State<TaskVerificationDialog> {
  final ImagePicker _picker = ImagePicker();
  final EnhancedAIService _aiService = EnhancedAIService();
  final TaskService _taskService = TaskService();
  final PointsService _pointsService = PointsService();

  File? _capturedImage;
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verify Task Completion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick actions
                if (_capturedImage != null) ...[
                  IconButton(
                    tooltip: 'Retake',
                    onPressed: _isVerifying
                        ? null
                        : () =>
                              _captureImage(ImageSource.camera, replace: true),
                    icon: const Icon(Icons.camera),
                  ),
                  IconButton(
                    tooltip: 'Pick from gallery',
                    onPressed: _isVerifying
                        ? null
                        : () =>
                              _captureImage(ImageSource.gallery, replace: true),
                    icon: const Icon(Icons.photo_library),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Take a photo to verify you completed this task. '
                      'We analyze it on-device and (optionally) via a free captioning API. '
                      'The photo is **not stored**.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preview or capture area
            if (_capturedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _capturedImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              _CapturePlaceholder(
                onCamera: () => _captureImage(ImageSource.camera),
                onGallery: () => _captureImage(ImageSource.gallery),
              ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifying
                        ? null
                        : () async {
                            await _deleteTempIfAny();
                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                    onPressed: (_capturedImage != null && !_isVerifying)
                        ? _verifyTask
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source, {bool replace = false}) async {
    try {
      final XFile? x = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (x == null) return;

      // Clean previous temp file if replacing
      if (replace) await _deleteTempIfAny();

      setState(() => _capturedImage = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
    }
  }

  Future<void> _verifyTask() async {
    final file = _capturedImage;
    if (file == null) return;

    setState(() => _isVerifying = true);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analyzing image…'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final isVerified = await _aiService.verifyTaskCompletion(
        widget.task.title,
        file,
      );
      final points = await _aiService.calculatePoints(
        widget.task.title,
        isVerified,
      );

      if (isVerified) {
        await _pointsService.awardPoints(
          points,
          'Task completed: ${widget.task.title}',
          taskId: widget.task.id,
        );
        await _taskService.updateTaskStatus(
          widget.task.id,
          TaskStatus.completed,
          pointsAwarded: points,
        );

        widget.onVerificationComplete(true, points);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Task verified! +$points points'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        await _deleteTempIfAny();
        if (mounted) Navigator.pop(context);
      } else {
        widget.onVerificationComplete(false, 0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❌ Couldn’t verify. Try a clearer photo.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Retake',
                onPressed: () => setState(() => _capturedImage = null),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _deleteTempIfAny() async {
    try {
      if (_capturedImage != null && await _capturedImage!.exists()) {
        await _capturedImage!.delete(); // best-effort delete the temp file
      }
    } catch (_) {}
    _capturedImage = null;
  }

  @override
  void dispose() {
    _deleteTempIfAny(); // cleanup on close
    super.dispose();
  }
}

class _CapturePlaceholder extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _CapturePlaceholder({
    required this.onCamera,
    required this.onGallery,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCamera,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Tap to take photo',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
