import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true; // Start with loading true
  bool _isInitialized = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    print('Initializing auth provider...');
    FirebaseService.authStateChanges.listen((User? firebaseUser) async {
      print('Auth state changed: ${firebaseUser?.uid}');

      _setLoading(true);

      if (firebaseUser != null) {
        try {
          print('Loading user data for: ${firebaseUser.uid}');
          _user = await FirebaseService.getUserData(firebaseUser.uid);
          print('User data loaded: ${_user?.name}');
        } catch (e) {
          print('Error loading user data: $e');
          _user = null;
        }
      } else {
        _user = null;
        print('No authenticated user');
      }

      _isInitialized = true;
      _setLoading(false);
      print('Auth initialization complete. Authenticated: ${isAuthenticated}');
    });
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('Attempting to sign up user: $email');
      _user = await FirebaseService.signUpWithEmailPassword(
        name: name,
        email: email,
        password: password,
      );

      _setLoading(false);
      bool success = _user != null;
      print('Sign up ${success ? 'successful' : 'failed'}');
      return success;
    } catch (e) {
      print('Sign up error: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      _clearError();

      print('Attempting to sign in user: $email');
      _user = await FirebaseService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      bool success = _user != null;
      print('Sign in ${success ? 'successful' : 'failed'}');
      return success;
    } catch (e) {
      print('Sign in error: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      print('Attempting Google sign in');
      _user = await FirebaseService.signInWithGoogle();

      _setLoading(false);
      bool success = _user != null;
      print('Google sign in ${success ? 'successful' : 'failed'}');
      return success;
    } catch (e) {
      print('Google sign in error: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      print('Attempting to sign out');
      _setLoading(true);
      await FirebaseService.signOut();
      _user = null;
      _clearError();
      _setLoading(false);
      print('Sign out successful');
    } catch (e) {
      print('Sign out error: $e');
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      print('Attempting to reset password for: $email');
      await FirebaseService.resetPassword(email);

      _setLoading(false);
      print('Password reset email sent');
      return true;
    } catch (e) {
      print('Password reset error: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
