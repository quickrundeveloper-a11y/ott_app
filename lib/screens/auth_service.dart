// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Your Google Web Client ID
  static const String googleWebClientId =
      "578839911643-mdjn5at4h5vrejrc09ig2d8d862lvnh1.apps.googleusercontent.com";

  /// ----------------------------------------------------------
  /// CHECK IF EMAIL EXISTS IN FIREBASE AUTH
  /// ----------------------------------------------------------
  Future<bool> userExistsByEmail(String email) async {
    try {
      List<String> methods =
      await _auth.fetchSignInMethodsForEmail(email.trim());
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint("Email check failed: $e");
      return false;
    }
  }

  /// ----------------------------------------------------------
  /// EMAIL LOGIN
  /// ----------------------------------------------------------
  Future<UserCredential> loginEmail(String email, String pass) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: pass.trim(),
    );
  }

  /// ----------------------------------------------------------
  /// CREATE EMAIL ACCOUNT
  /// ----------------------------------------------------------
  Future<UserCredential> createEmail(String email, String pass) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: pass.trim(),
    );
  }

  /// ----------------------------------------------------------
  /// GOOGLE LOGIN
  /// ----------------------------------------------------------
  Future<UserCredential> loginGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email'],
      clientId: googleWebClientId,
    );

    final gUser = await googleSignIn.signIn();
    if (gUser == null) {
      throw FirebaseAuthException(
        code: "cancelled",
        message: "Google Sign-in cancelled",
      );
    }

    final gAuth = await gUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    return await _auth.signInWithCredential(cred);
  }

  /// ----------------------------------------------------------
  /// SAVE PROFILE (USED IN COMPLETE PROFILE)
  /// ----------------------------------------------------------
  Future<void> saveProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required DateTime dob,
    required String gender,
    String? email,
  }) async {
    try {
      await _db.collection("users").doc(uid).set({
        "uid": uid,
        "firstName": firstName,
        "lastName": lastName,
        "dob": dob.toIso8601String(),
        "gender": gender,
        if (email != null) "email": email,
        "updatedAt": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to save profile: $e");
      throw Exception("Profile could not be saved");
    }
  }

  /// ----------------------------------------------------------
  /// CHECK IF USER PROFILE EXISTS IN FIRESTORE
  /// ----------------------------------------------------------
  Future<bool> profileExists(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    return doc.exists;
  }

  /// ----------------------------------------------------------
  /// LOGOUT
  /// ----------------------------------------------------------
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
}
