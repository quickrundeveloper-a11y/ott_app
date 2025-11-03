import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _loading = false;

  bool _isNewUser = false;
  bool _checkedEmail = false;

  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  /// When the screen is created, if a user is already authenticated,
  /// check if their `users/{uid}` document exists and navigate accordingly.
  Future<void> _checkCurrentUser() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return; // no signed-in user

    if (mounted) setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(current.uid).get();
      if (!mounted) return;

      if (doc.exists) {
        // existing user -> Home
        Navigator.pushReplacementNamed(context, HomeScreen.route);
      } else {
        // new / missing profile -> Complete profile
        Navigator.pushReplacementNamed(
          context,
          CompleteProfileScreen.route,
          arguments: CompleteProfileArgs(uid: current.uid, email: current.email),
        );
      }
    } catch (e) {
      // on error, fallback to CompleteProfile so user can finish setup
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        CompleteProfileScreen.route,
        arguments: CompleteProfileArgs(uid: current.uid, email: current.email),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _navigateAfterSignIn(User user) async {
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
      // If Firestore check fails, fallback to CompleteProfile to avoid blocking the user
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
      final pass = _password.text;

      final exists = await _authService.userExistsByEmail(email);
      setState(() {
        _isNewUser = !exists;
        _checkedEmail = true;
      });

      if (!exists) {
        // 🆕 NEW USER
        if (_confirm.text.isEmpty) {
          _snack('Confirm your password to create account');
          return;
        }
        if (_confirm.text != pass) {
          _snack('Passwords do not match');
          return;
        }

        final cred = await _authService.createUserWithEmail(email: email, password: pass);

        await _authService.saveBasicUserDoc(uid: cred.user!.uid, email: email);

        // Go to complete profile first (new user)
        if (!mounted) return;
        await _navigateAfterSignIn(cred.user!);
      } else {
        // ✅ EXISTING USER → login → home
        final cred = await _authService.signInWithEmail(email: email, password: pass);
        await _navigateAfterSignIn(cred.user!);
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
      // Attempt Google sign-in via your AuthService
      final cred = await _authService.signInWithGoogle();

      final user = cred.user!;
      // Decide where to send the user depending on whether their users/doc exists
      await _navigateAfterSignIn(user);
    } on FirebaseAuthException catch (e) {
      // Firebase-specific errors
      _snack(e.message ?? e.code);
    } on PlatformException catch (e) {
      // Handle Google Sign-In / Play Services errors (ApiException: 10 is common for SHA mismatch)
      final code = e.code ?? 'unknown';
      _snack('Google sign-in failed (code: $code).\nIf you see ApiException: 10, add your Android app SHA-1 to Firebase console and update the OAuth client in Google Cloud.');
      // optional: print full details to console for debugging
      // ignore: avoid_print
      print('PlatformException during Google sign-in: ${e.code} | ${e.message} | ${e.details}');
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFB6FF3B);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Welcome !',
                style: TextStyle(
                  color: lime,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your Email',
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: lime, width: 1.6),
                        ),
                        hintStyle: const TextStyle(color: Color(0xFFBEBEBE)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
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
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter Password',
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: lime, width: 1.6),
                        ),
                        hintStyle: const TextStyle(color: Color(0xFFBEBEBE)),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Password required';
                        if ((v ?? '').length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),

                    // Confirm password for new users
                    if (_isNewUser || (_checkedEmail && _isNewUser))
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          controller: _confirm,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: lime, width: 1.6),
                            ),
                            hintStyle: const TextStyle(color: Color(0xFFBEBEBE)),
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          validator: (_) {
                            if (!_isNewUser) return null;
                            if (_confirm.text.isEmpty) return 'Confirm your password';
                            if (_confirm.text != _password.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Terms
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                    side: const BorderSide(color: lime),
                    activeColor: lime,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Please accept the ',
                        children: [
                          TextSpan(
                            text: 'Terms & Condition',
                            style: TextStyle(color: lime, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      style: TextStyle(color: Color(0xFFE8E8E8)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Main button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _acceptedTerms ? lime : const Color(0xFF2B2B2B),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _acceptedTerms && !_loading ? _handleEmailButton : null,
                  child: _loading
                      ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                    _isNewUser ? 'CREATE ACCOUNT' : 'LOG IN',
                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Center(child: Text('OR', style: TextStyle(color: Color(0xFFBEBEBE)))),
              const SizedBox(height: 16),

              // Google Sign-In button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _handleGoogleLogin,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF2A2A2A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save user login state to SharedPreferences
  Future<void> saveLoginState({
    required String uid,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('uid', uid);
    await prefs.setString('email', email);
  }

  /// Clear user login state (for logout)
  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('uid');
    await prefs.remove('email');
  }

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
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await saveLoginState(uid: cred.user!.uid, email: email);
    return cred;
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
      final cred = await _auth.signInWithPopup(provider);
      await saveLoginState(uid: cred.user!.uid, email: cred.user?.email ?? '');
      return cred;
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
      final cred = await _auth.signInWithCredential(credential);
      await saveLoginState(uid: cred.user!.uid, email: cred.user?.email ?? '');
      return cred;
    }
  }
}
