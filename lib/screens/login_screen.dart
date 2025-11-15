import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';


/// ---------------------
/// AuthService
/// ---------------------
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String googleWebClientId =
      "578839911643-mdjn5at4h5vrejrc09ig2d8d862lvnh1.apps.googleusercontent.com";

  Future<void> saveLoginState({required String uid, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('uid', uid);
    await prefs.setString('email', email);
  }

  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// ✅ Fully reliable email existence check
  Future<bool> userExistsByEmail(String email) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Try twice because sometimes first call returns empty
      List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        methods = await _auth.fetchSignInMethodsForEmail(email);
      }

      debugPrint("Firebase methods for $email => $methods");
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint("userExistsByEmail error: $e");
      return false;
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred =
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await saveLoginState(uid: cred.user!.uid, email: email);
    return cred;
  }

  Future<UserCredential> createUserWithEmail({
    required String email,
    required String password,
  }) async {
    final cred =
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await saveLoginState(uid: cred.user!.uid, email: email);
    return cred;
  }

  Future<void> saveProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required DateTime dob,
    required String gender,
    String? email,
  }) async {
    await _db.collection('users').doc(uid).set({
      if (email != null) 'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dob': dob,
      'gender': gender,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      final cred = await _auth.signInWithPopup(provider);
      await saveLoginState(uid: cred.user!.uid, email: cred.user?.email ?? '');
      return cred;
    } else {
      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
        clientId: googleWebClientId,
      );
      final gUser = await googleSignIn.signIn();
      if (gUser == null) {
        throw FirebaseAuthException(code: 'canceled', message: 'Google sign-in canceled');
      }
      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      await saveLoginState(uid: cred.user!.uid, email: cred.user?.email ?? '');
      return cred;
    }
  }
}

/// ---------------------
/// Login Screen
/// ---------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _loading = false;
  bool _isNewUser = false;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _navigateAfterSignIn(User user, {bool isNew = false}) async {
    if (isNew) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        CompleteProfileScreen.route,
        arguments: CompleteProfileArgs(uid: user.uid, email: user.email),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, HomeScreen.route);
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          CompleteProfileScreen.route,
          arguments: CompleteProfileArgs(uid: user.uid, email: user.email),
        );
      }
    } catch (e) {
      _snack('Could not verify profile. Please complete your profile.');
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        CompleteProfileScreen.route,
        arguments: CompleteProfileArgs(uid: user.uid, email: user.email),
      );
    }
  }

  Future<void> _handleEmailButton() async {
    if (!_formKey.currentState!.validate() || !_acceptedTerms) return;

    setState(() => _loading = true);
    try {
      final email = _email.text.trim();
      final pass = _password.text.trim();

      final exists = await _authService.userExistsByEmail(email);

      if (exists) {
        // ✅ Existing Firebase user → login directly
        final cred = await _authService.signInWithEmail(email: email, password: pass);
        await _navigateAfterSignIn(cred.user!);
      } else {
        // 🆕 New user → confirm password → create account
        if (!_isNewUser) {
          setState(() => _isNewUser = true);
          _snack('New email detected — confirm password to create account');
          return;
        }

        if (_confirm.text.isEmpty) {
          _snack('Please confirm your password');
          return;
        }
        if (_confirm.text != pass) {
          _snack('Passwords do not match');
          return;
        }

        final cred = await _authService.createUserWithEmail(email: email, password: pass);
        if (!mounted) return;
        await _navigateAfterSignIn(cred.user!, isNew: true);
      }
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      await _navigateAfterSignIn(cred.user!);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } on PlatformException catch (e) {
      _snack('Google sign-in failed (code: ${e.code}). Add SHA-1 if needed.');
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome !',
                style: TextStyle(
                    color: AppTheme.greenAccent, fontSize: 36, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column( // Use a container for consistent styling
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: AppTheme.inputDecoration(
                          hint: 'Enter your Email',
                          suffix: const Icon(Icons.email_outlined, color: AppTheme.textGrey),
                        ),
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) return 'Email required';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(text)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: AppTheme.inputDecoration(
                          hint: 'Enter Password',
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                                _obscure ? Icons.visibility : Icons.visibility_off,
                                color: AppTheme.textGrey),
                          ),
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Password required';
                          if ((v ?? '').length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                    ),

                    if (_isNewUser)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextFormField(
                            controller: _confirm,
                            obscureText: _obscureConfirm,
                            style: const TextStyle(color: AppTheme.textWhite),
                            decoration: AppTheme.inputDecoration(
                              hint: 'Confirm Password',
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppTheme.textGrey),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (v) =>
                        setState(() => _acceptedTerms = v ?? false),
                    activeColor: AppTheme.greenAccent,
                  ),
                  const Expanded(
                    child: Text('Accept Terms & Conditions',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _acceptedTerms
                        ? AppTheme.greenAccent
                        : AppTheme.cardDarker,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _acceptedTerms && !_loading
                      ? _handleEmailButton
                      : null,
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isNewUser ? 'CREATE ACCOUNT' : 'LOG IN',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                  child: Text('OR',
                      style: TextStyle(color: AppTheme.textGrey))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                    foregroundColor: AppTheme.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : _handleGoogleLogin,
                  icon:
                      const Icon(Icons.account_circle_outlined, color: AppTheme.textLight),
                  label: const Text('Continue with Google'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

