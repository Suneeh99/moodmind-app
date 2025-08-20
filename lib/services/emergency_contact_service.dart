import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact_model.dart';
import '../services/firebase_service.dart';

class EmergencyContactService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'emergency_contacts';

  // Get all emergency contacts for current user
  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => EmergencyContact.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting emergency contacts: $e');
      return [];
    }
  }

  // Add emergency contact
  static Future<bool> addEmergencyContact({
    required String name,
    required String phoneNumber,
    required String relationship,
  }) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw 'User not authenticated';

      final docRef = _firestore.collection(_collection).doc();
      final contact = EmergencyContact(
        id: docRef.id,
        userId: userId,
        name: name,
        phoneNumber: phoneNumber,
        relationship: relationship,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(contact.toMap());
      print('Emergency contact added successfully');
      return true;
    } catch (e) {
      print('Error adding emergency contact: $e');
      return false;
    }
  }

  // Update emergency contact
  static Future<bool> updateEmergencyContact({
    required String contactId,
    required String name,
    required String phoneNumber,
    required String relationship,
  }) async {
    try {
      await _firestore.collection(_collection).doc(contactId).update({
        'name': name,
        'phoneNumber': phoneNumber,
        'relationship': relationship,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('Emergency contact updated successfully');
      return true;
    } catch (e) {
      print('Error updating emergency contact: $e');
      return false;
    }
  }

  // Delete emergency contact
  static Future<bool> deleteEmergencyContact(String contactId) async {
    try {
      await _firestore.collection(_collection).doc(contactId).delete();
      print('Emergency contact deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting emergency contact: $e');
      return false;
    }
  }

  // Delete all emergency contacts for user
  static Future<bool> deleteAllEmergencyContacts() async {
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
      print('All emergency contacts deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting all emergency contacts: $e');
      return false;
    }
  }

  // Get emergency contact by ID
  static Future<EmergencyContact?> getEmergencyContactById(
    String contactId,
  ) async {
    try {
      final doc = await _firestore.collection(_collection).doc(contactId).get();
      if (doc.exists) {
        return EmergencyContact.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting emergency contact: $e');
      return null;
    }
  }
}
