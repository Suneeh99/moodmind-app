import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Configure GoogleSignIn with proper parameters
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserModel?> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // Create user document in Firestore
        UserModel userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _createUserDocument(userModel);
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during signup: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during signup: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
    return null;
  }

  // Sign in with email and password
  static Future<UserModel?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Update last login time
        await _updateLastLogin(user.uid);
        return await getUserData(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during signin: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during signin: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
    return null;
  }

  // Sign in with Google
  static Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If the user cancels the sign-in process
      if (googleUser == null) {
        print('Google sign-in was cancelled by user');
        return null;
      }

      print('Google user signed in: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        print('Firebase user created/signed in: ${user.uid}');

        // Check if user document exists
        UserModel? existingUser = await getUserData(user.uid);

        if (existingUser == null) {
          print('Creating new user document for: ${user.uid}');
          // Create new user document
          UserModel userModel = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _createUserDocument(userModel);
          return userModel;
        } else {
          print('User document exists, updating last login');
          // Update last login
          await _updateLastLogin(user.uid);
          return existingUser;
        }
      }
    } on FirebaseAuthException catch (e) {
      print(
        'FirebaseAuthException during Google signin: ${e.code} - ${e.message}',
      );
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during Google signin: $e');
      throw 'Google sign-in failed. Please try again.';
    }
    return null;
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      // Still try to sign out from Firebase Auth even if Google sign out fails
      await _auth.signOut();
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('Error sending password reset email: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  static Future<UserModel?> getUserData(String uid) async {
    try {
      print('Fetching user data for UID: $uid');
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        print('User document found, parsing data...');
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Raw user data: $data');

        UserModel user = UserModel.fromMap(data);
        print('Parsed user model: $user');
        return user;
      } else {
        print('No user document found for UID: $uid');
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Create user document in Firestore
  static Future<void> _createUserDocument(UserModel user) async {
    try {
      print('Creating user document for: ${user.uid}');
      Map<String, dynamic> userData = user.toMap();
      print('User data to save: $userData');

      await _firestore.collection('users').doc(user.uid).set(userData);
      print('User document created successfully');
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  // Update last login time
  static Future<void> _updateLastLogin(String uid) async {
    try {
      print('Updating last login for UID: $uid');
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      print('Last login updated successfully');
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? photoUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (name != null) {
        updates['name'] = name;
        await currentUser?.updateDisplayName(name);
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        await currentUser?.updatePhotoURL(photoUrl);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
        print('User profile updated successfully');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Check if user is currently signed in
  static bool get isSignedIn => _auth.currentUser != null;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return 'An error occurred: ${e.message ?? 'Please try again.'}';
    }
  }
}
