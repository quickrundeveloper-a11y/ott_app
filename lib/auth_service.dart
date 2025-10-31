import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Web client ID for Google Sign-In (Android uses this when required)
  static const String googleWebClientId =
      "578839911643-mdjn5at4h5vrejrc09ig2d8d862lvnh1.apps.googleusercontent.com";

  /// Check if an email already has sign-in methods (i.e., user exists)
  Future<bool> userExistsByEmail(String email) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

  /// Sign in existing account
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Create new account
  Future<UserCredential> createUserWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Create/merge a minimal user document right after account creation
  Future<void> saveBasicUserDoc({
    required String uid,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ✅ Save full profile fields (used by CompleteProfileScreen)
  Future<void> saveProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required DateTime dob,
    required String gender, // 'male' | 'female'
    String? email,
  }) async {
    await _db.collection('users').doc(uid).set({
      if (email != null) 'email': email,
      'firstName': firstName,
      'lastName': lastName,
      // Firestore stores DateTime as Timestamp automatically
      'dob': dob,
      'gender': gender,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Google Sign-In (Android/iOS & Web)
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      return await _auth.signInWithPopup(provider);
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        clientId: googleWebClientId,
      );

      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      if (gUser == null) {
        throw FirebaseAuthException(code: 'canceled', message: 'Google sign-in canceled');
      }

      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    }
  }
}
