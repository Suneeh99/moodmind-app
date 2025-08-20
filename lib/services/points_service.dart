// lib/services/points_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/points_model.dart';

class PointsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  /// Stream the current user's total points as UserPoints object.
  Stream<UserPoints?> getCurrentUserPoints() {
    if (_uid.isEmpty) {
      // Emit null if not signed in
      return Stream<UserPoints?>.value(null);
    }
    final docRef = _db.collection('users').doc(_uid);
    return docRef.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      
      final pts = data['points'] ?? 0;
      final points = pts is int ? pts : (pts is double ? pts.toInt() : 0);
      
      return UserPoints(
        userId: _uid,
        userName: data['displayName'] ?? 'User',
        photoUrl: data['photoUrl'],
        totalPoints: points,
        rank: 0, // We'll calculate rank separately if needed
        lastUpdated: DateTime.now(),
      );
    });
  }

  /// Stream a leaderboard as list of UserPoints objects.
  /// Adjust the `limit` to taste (defaults to top 20).
  Stream<List<UserPoints>> getLeaderboard({int limit = 20}) {
    final q = _db
        .collection('users')
        .orderBy('points', descending: true)
        .limit(limit);

    return q.snapshots().map((snap) {
      final users = <UserPoints>[];
      for (int i = 0; i < snap.docs.length; i++) {
        final d = snap.docs[i];
        final data = d.data();
        final rawPoints = data['points'] ?? 0;
        final points = rawPoints is int
            ? rawPoints
            : (rawPoints is double ? rawPoints.toInt() : 0);
        
        users.add(UserPoints(
          userId: d.id,
          userName: data['displayName'] ?? 'User',
          photoUrl: data['photoUrl'],
          totalPoints: points,
          rank: i + 1, // Rank based on position in ordered list
          lastUpdated: DateTime.now(),
        ));
      }
      return users;
    });
  }

  /// Stream the current user's points history as PointsTransaction objects, newest first.
  Stream<List<PointsTransaction>> getPointsHistory() {
    if (_uid.isEmpty) {
      return Stream<List<PointsTransaction>>.value(const []);
    }

    final q = _db
        .collection('users')
        .doc(_uid)
        .collection('points_ledger')
        .orderBy('createdAt', descending: true);

    return q.snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        final ts = data['createdAt'];
        DateTime createdAt = DateTime.now();
        if (ts is Timestamp) createdAt = ts.toDate();

        final rawPoints = data['points'] ?? 0;
        final points = rawPoints is int
            ? rawPoints
            : (rawPoints is double ? rawPoints.toInt() : 0);

        return PointsTransaction(
          id: d.id,
          userId: _uid,
          points: points,
          type: points >= 0 ? PointsTransactionType.earned : PointsTransactionType.deducted,
          reason: data['reason'] ?? '',
          taskId: data['taskId'],
          createdAt: createdAt,
        );
      }).toList();
    });
  }

  /// Writes a ledger record and increments user's total points.
  Future<void> awardPoints(int points, String reason, {String? taskId}) async {
    if (_uid.isEmpty || points <= 0) return;

    final userRef = _db.collection('users').doc(_uid);
    final ledgerRef = userRef.collection('points_ledger').doc();

    final batch = _db.batch();

    batch.set(ledgerRef, {
      'id': ledgerRef.id,
      'points': points,
      'reason': reason,
      'taskId': taskId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(userRef, {
      'points': FieldValue.increment(points),
      // ensure user exists even if not created elsewhere
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
