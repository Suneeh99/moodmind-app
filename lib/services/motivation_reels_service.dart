import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/motivation_reel.dart';

class MotivationReelsService {
  final _col = FirebaseFirestore.instance.collection('motivation_reels');

  Stream<List<MotivationReel>> streamActive() {
    return _col
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MotivationReel.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
