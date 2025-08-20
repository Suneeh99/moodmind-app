import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry_model.dart';
import '../models/mood_statistics_model.dart';
import '../services/sentiment_analysis_service.dart';
import '../services/firebase_service.dart';

class DiaryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'diary_entries';

  // Save diary entry immediately, then analyze sentiment in background
  static Future<DiaryEntryModel?> saveDiaryEntry({
    required String title,
    required String content,
    required DateTime date,
  }) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        throw 'User not authenticated';
      }

      print('Saving diary entry for user: $userId on date: $date');

      // Check if entry already exists for this date
      final existingEntry = await getDiaryEntry(date);
      if (existingEntry != null) {
        // Update existing entry immediately
        return await updateDiaryEntry(
          entryId: existingEntry.id,
          title: title,
          content: content,
        );
      }

      // Create diary entry with normalized date (start of day)
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final entryId = _firestore.collection(_collection).doc().id;

      // Create entry with undefined sentiment initially
      final diaryEntry = DiaryEntryModel(
        id: entryId,
        userId: userId,
        title: title,
        content: content,
        date: normalizedDate,
        createdAt: DateTime.now(),
        sentimentAnalysis: {}, // Empty initially
        dominantEmotion: 'undefined', // Default value
        confidenceScore: 0.0, // Default value
      );

      // Save to Firestore immediately
      await _firestore
          .collection(_collection)
          .doc(entryId)
          .set(diaryEntry.toMap());

      print('Diary entry saved immediately');

      // Start fast background analysis (don't await)
      _analyzeSentimentInBackground(entryId, content);

      return diaryEntry;
    } catch (e) {
      print('Error saving diary entry: $e');
      rethrow;
    }
  }

  // Optimized background sentiment analysis
  static Future<void> _analyzeSentimentInBackground(
    String entryId,
    String content,
  ) async {
    try {
      print('Starting fast background sentiment analysis for entry: $entryId');

      // Use optimized local analysis first for speed
      Map<String, dynamic> sentimentResult =
          SentimentAnalysisService.analyzeLocalSentiment(content);

      // Update immediately with local analysis
      if (sentimentResult['success']) {
        await _firestore.collection(_collection).doc(entryId).update({
          'sentimentAnalysis': sentimentResult['emotions'] ?? {},
          'dominantEmotion': sentimentResult['dominantEmotion'] ?? 'neutral',
          'confidenceScore': sentimentResult['confidenceScore'] ?? 0.5,
        });
        print('Fast local analysis completed and saved');
      }

      // Try API analysis in background for better accuracy (optional)
      try {
        final apiResult = await SentimentAnalysisService.analyzeSentiment(
          content,
        );
        if (apiResult['success'] &&
            apiResult['dominantEmotion'] !=
                sentimentResult['dominantEmotion']) {
          // Only update if API gives different/better result
          await _firestore.collection(_collection).doc(entryId).update({
            'sentimentAnalysis': apiResult['emotions'] ?? {},
            'dominantEmotion': apiResult['dominantEmotion'] ?? 'neutral',
            'confidenceScore': apiResult['confidenceScore'] ?? 0.5,
          });
          print('API analysis completed and updated');
        }
      } catch (e) {
        print('API analysis failed, keeping local analysis: $e');
      }
    } catch (e) {
      print('Error in background sentiment analysis: $e');
      // Keep entry as saved with undefined sentiment
    }
  }

  // Get diary entry for specific date
  static Future<DiaryEntryModel?> getDiaryEntry(DateTime date) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        print('User not authenticated');
        return null;
      }

      // Normalize date to start of day for consistent querying
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Query for entry on specific date
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final entry = DiaryEntryModel.fromMap(querySnapshot.docs.first.data());
        return entry;
      }

      return null;
    } catch (e) {
      print('Error getting diary entry: $e');
      return null;
    }
  }

  // Get diary entries for a date range
  static Future<List<DiaryEntryModel>> getDiaryEntries({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        print('User not authenticated');
        return [];
      }

      // Normalize dates
      final normalizedStartDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final normalizedEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStartDate),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(normalizedEndDate),
          )
          .orderBy('date', descending: true)
          .get();

      final entries = querySnapshot.docs
          .map((doc) => DiaryEntryModel.fromMap(doc.data()))
          .toList();

      return entries;
    } catch (e) {
      print('Error getting diary entries: $e');
      return [];
    }
  }

  // Get mood statistics for different periods
  static Future<MoodStatisticsModel> getMoodStatistics(String period) async {
    DateTime endDate = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'Today':
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        break;
      case 'This week':
        // Get start of current week (Monday)
        int daysFromMonday = endDate.weekday - 1;
        startDate = endDate.subtract(Duration(days: daysFromMonday));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        break;
      case 'This Month':
        startDate = DateTime(endDate.year, endDate.month, 1);
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        break;
      default:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
    }

    final entries = await getDiaryEntries(
      startDate: startDate,
      endDate: endDate,
    );

    return MoodStatisticsModel.fromEntries(entries, period, startDate, endDate);
  }

  // Update diary entry immediately, then analyze sentiment in background
  static Future<DiaryEntryModel?> updateDiaryEntry({
    required String entryId,
    required String title,
    required String content,
  }) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        throw 'User not authenticated';
      }

      print('Updating diary entry: $entryId');

      // Update entry immediately with undefined sentiment
      await _firestore.collection(_collection).doc(entryId).update({
        'title': title,
        'content': content,
        'sentimentAnalysis': {}, // Reset to empty
        'dominantEmotion': 'undefined', // Reset to undefined
        'confidenceScore': 0.0, // Reset to 0
      });

      // Get updated entry
      final doc = await _firestore.collection(_collection).doc(entryId).get();
      DiaryEntryModel? updatedEntry;
      if (doc.exists) {
        updatedEntry = DiaryEntryModel.fromMap(doc.data()!);
        print('Entry updated immediately');
      }

      // Analyze sentiment in background
      _analyzeSentimentInBackground(entryId, content);

      return updatedEntry;
    } catch (e) {
      print('Error updating diary entry: $e');
      rethrow;
    }
  }

  // Check if entry exists for date
  static Future<bool> entryExistsForDate(DateTime date) async {
    final entry = await getDiaryEntry(date);
    return entry != null;
  }

  // Get all diary entries for a user (for debugging)
  static Future<List<DiaryEntryModel>> getAllUserEntries() async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      final entries = querySnapshot.docs
          .map((doc) => DiaryEntryModel.fromMap(doc.data()))
          .toList();

      return entries;
    } catch (e) {
      print('Error getting all user entries: $e');
      return [];
    }
  }

  // Add this method to your existing DiaryService class

  static Future<bool> deleteAllDiaryEntries() async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw 'User not authenticated';

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All diary entries deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting all diary entries: $e');
      return false;
    }
  }

  // Also add individual diary entry deletion
  static Future<bool> deleteDiaryEntry(String entryId) async {
    try {
      await _firestore.collection(_collection).doc(entryId).delete();
      print('Diary entry deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting diary entry: $e');
      return false;
    }
  }
}
