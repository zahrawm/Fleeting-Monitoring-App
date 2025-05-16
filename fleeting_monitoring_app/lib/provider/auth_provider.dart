import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
    });
    _user = _auth.currentUser;
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    debugPrint('Auth Error: $error');
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        _setError("Google sign-in was cancelled.");
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      _user = userCredential.user;

      if (_user == null) {
        _setLoading(false);
        _setError("User ID cannot be found after Google Sign-In.");
        return false;
      }

      debugPrint("Signed in with Google: UID = ${_user!.uid}");

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError("Google Sign-In failed: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;

      notifyListeners();
    } catch (e) {
      _setError("Sign out failed: $e");
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
