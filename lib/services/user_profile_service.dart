import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'users';

  // Get current user profile
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) return null;

      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile (without email change)
  static Future<bool> updateUserProfile({
    required String username,
    String? profileImagePath,
  }) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw 'User not authenticated';

      String? profileImageUrl;

      // Upload profile image if provided
      if (profileImagePath != null) {
        profileImageUrl = await _uploadProfileImage(userId, profileImagePath);
      }

      // Update display name in Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(username);
      }

      // Get current user data
      final currentUserDoc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get();
      UserModel? currentUserModel;

      if (currentUserDoc.exists) {
        currentUserModel = UserModel.fromMap(currentUserDoc.data()!);
      }

      // Update profile in Firestore (keep existing email and preferences)
      final updatedUser =
          currentUserModel?.copyWith(
            name: username,
            photoUrl: profileImageUrl ?? currentUserModel.photoUrl,
            lastLoginAt: DateTime.now(),
          ) ??
          UserModel(
            uid: userId,
            name: username,
            email: currentUser?.email ?? '',
            photoUrl: profileImageUrl,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(updatedUser.toMap(), SetOptions(merge: true));

      print('User profile updated successfully');
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Send email verification for email change
  static Future<bool> requestEmailChange(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Check if email is already in use
      final methods = await _auth.fetchSignInMethodsForEmail(newEmail);
      if (methods.isNotEmpty) {
        throw 'Email is already in use by another account';
      }

      // Send verification email to new address
      await user.verifyBeforeUpdateEmail(newEmail);

      print('Email verification sent to: $newEmail');
      return true;
    } catch (e) {
      print('Error requesting email change: $e');
      return false;
    }
  }

  // Update email after verification (call this after user clicks verification link)
  static Future<bool> updateEmailAfterVerification(String newEmail) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw 'User not authenticated';

      // Update email in Firestore
      await _firestore.collection(_collection).doc(userId).update({
        'email': newEmail,
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      print('Email updated successfully in Firestore');
      return true;
    } catch (e) {
      print('Error updating email in Firestore: $e');
      return false;
    }
  }

  // Upload profile image
  static Future<String?> _uploadProfileImage(
    String userId,
    String imagePath,
  ) async {
    try {
      final file = File(imagePath);
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      print('Profile image uploaded successfully');
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Pick and upload profile image
  static Future<String?> pickAndUploadProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final userId = FirebaseService.currentUserId;
        if (userId != null) {
          return await _uploadProfileImage(userId, pickedFile.path);
        }
      }
      return null;
    } catch (e) {
      print('Error picking profile image: $e');
      return null;
    }
  }

  // Update password
  static Future<bool> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      print('Password updated successfully');
      return true;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }

  // Delete user account
  static Future<bool> deleteUserAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      final userId = user.uid;

      // Delete user data from Firestore
      await _deleteUserData(userId);

      // Delete user account
      await user.delete();

      print('User account deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting user account: $e');
      return false;
    }
  }

  // Delete all user data
  static Future<void> _deleteUserData(String userId) async {
    try {
      // Delete user profile
      await _firestore.collection(_collection).doc(userId).delete();

      // Delete diary entries
      final diaryQuery = await _firestore
          .collection('diary_entries')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in diaryQuery.docs) {
        await doc.reference.delete();
      }

      // Delete emergency contacts
      final contactsQuery = await _firestore
          .collection('emergency_contacts')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in contactsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete profile image from storage
      try {
        await _storage
            .ref()
            .child('profile_images')
            .child('$userId.jpg')
            .delete();
      } catch (e) {
        print('Profile image not found or already deleted');
      }

      print('All user data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  // Update user preferences
  static Future<bool> updateUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw 'User not authenticated';

      await _firestore.collection(_collection).doc(userId).update({
        'preferences': preferences,
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      print('User preferences updated successfully');
      return true;
    } catch (e) {
      print('Error updating user preferences: $e');
      return false;
    }
  }

  // Get user preferences
  static Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final user = await getCurrentUserProfile();
      return user?.preferences;
    } catch (e) {
      print('Error getting user preferences: $e');
      return null;
    }
  }
}
