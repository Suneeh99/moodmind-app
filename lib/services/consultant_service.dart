import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/consultant_model.dart';

class ConsultantService {
  ConsultantService._();
  static final ConsultantService instance = ConsultantService._();

  final _db = FirebaseFirestore.instance;

  Stream<List<ConsultantModel>> streamConsultants({bool onlyVerified = true}) {
    Query<Map<String, dynamic>> q = _db
        .collection('users')
        .where('role', isEqualTo: 'consultant');

    if (onlyVerified) {
      q = q.where('verified', isEqualTo: true);
    }

    q = q.orderBy('displayName');
    debugPrint('ConsultantService: $q');
    return q.snapshots().map((snap) {
      return snap.docs.map((doc) => _fromUserDoc(doc)).toList();
    });
  }

  Future<ConsultantModel?> getConsultantById(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return _fromUserDoc(doc);
  }

  ConsultantModel _fromUserDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    return ConsultantModel(
      id: doc.id,
      displayName:
          (d['displayName'] as String?) ??
          (d['name'] as String?) ??
          'Consultant',
      email: (d['email'] as String?) ?? 'Counseling',
    );
  }
}
