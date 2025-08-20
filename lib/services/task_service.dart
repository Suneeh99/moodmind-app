import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Add a new task
  Future<void> addTask(Task task) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .set(task.toMap());
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  // Get tasks for a specific date
  Stream<List<Task>> getTasksForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .orderBy('timeHour')
        .orderBy('timeMinute')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data()))
            .toList());
  }

  // Get all tasks for current user
  Stream<List<Task>> getAllTasks() {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data()))
            .toList());
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status, {
    String? verificationPhotoUrl,
    int? pointsAwarded,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'completedAt': status == TaskStatus.completed 
            ? Timestamp.fromDate(DateTime.now()) 
            : null,
      };

      if (verificationPhotoUrl != null) {
        updateData['verificationPhotoUrl'] = verificationPhotoUrl;
      }

      if (pointsAwarded != null) {
        updateData['pointsAwarded'] = pointsAwarded;
      }

      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Get pending tasks that are due
  Stream<List<Task>> getDueTasks() {
    final now = DateTime.now();
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Task.fromMap(doc.data()))
              .where((task) {
                final scheduledTime = task.scheduledDateTime;
                return scheduledTime.isBefore(now) || 
                       scheduledTime.isAtSameMomentAs(now);
              })
              .toList();
        });
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Get tasks by status
  Stream<List<Task>> getTasksByStatus(TaskStatus status) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data()))
            .toList());
  }
}
