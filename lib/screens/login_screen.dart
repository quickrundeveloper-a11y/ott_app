import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../theme/theme.dart';
import 'auth_service.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmC = TextEditingController();

  final AuthService _auth = AuthService();

  bool showPasswordFields = false;
  bool existingUser = false;
  bool obscure = true;
  bool obscureC = true;
  bool loading = false;

  void popup(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ----------------------------------------------------------
  /// NAVIGATION AFTER LOGIN / SIGNUP
  /// ----------------------------------------------------------
  Future<void> navigateAfter(User user, {bool newUser = false}) async {
    final uid = user.uid;

    if (newUser) {
      Navigator.pushReplacementNamed(
        context,
        CompleteProfileScreen.route,
        arguments: CompleteProfileArgs(uid: uid, email: user.email),
      );
      return;
    }

    // Check Firestore profile
    final exists = await _auth.profileExists(uid);

    if (exists) {
      Navigator.pushReplacementNamed(context, HomeScreen.route);
    } else {
      Navigator.pushReplacementNamed(
        context,
        CompleteProfileScreen.route,
        arguments: CompleteProfileArgs(uid: uid, email: user.email),
      );
    }
  }

  /// ----------------------------------------------------------
  /// STEP 1 : CHECK EMAIL → decide login OR signup
  /// ----------------------------------------------------------
  Future<void> checkEmail() async {
    final email = emailC.text.trim();

    if (email.isEmpty) {
      popup("Enter your email");
      return;
    }

    setState(() => loading = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: email)
          .get();

      existingUser = snap.docs.isNotEmpty;
      showPasswordFields = true;

      popup(existingUser
          ? "Existing user — enter password"
          : "New user — create password");
    } catch (e) {
      popup("Error checking email");
    } finally {
      setState(() => loading = false);
    }
  }

  /// ----------------------------------------------------------
  /// STEP 2 : LOGIN OR SIGNUP FINAL ACTION
  /// ----------------------------------------------------------
  Future<void> handleFinalSubmit() async {
    final email = emailC.text.trim();
    final pass = passC.text.trim();

    if (pass.isEmpty) {
      popup("Password required");
      return;
    }

    if (!existingUser && confirmC.text.trim() != pass) {
      popup("Passwords do not match");
      return;
    }

    setState(() => loading = true);

    try {
      if (existingUser) {
        final cred = await _auth.loginEmail(email, pass);
        await navigateAfter(cred.user!);
      } else {
        final cred = await _auth.createEmail(email, pass);
        await navigateAfter(cred.user!, newUser: true);
      }
    } catch (e) {
      popup(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  /// ----------------------------------------------------------
  /// GOOGLE LOGIN
  /// ----------------------------------------------------------
  Future<void> handleGoogle() async {
    setState(() => loading = true);

    try {
      final cred = await _auth.loginGoogle();
      await navigateAfter(cred.user!);
    } catch (e) {
      popup("Google login failed");
    } finally {
      setState(() => loading = false);
    }
  }

  /// ----------------------------------------------------------
  /// UI
  /// ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              Text(
                "Welcome !",
                style: TextStyle(
                  color: AppTheme.greenAccent,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 30),

              /// EMAIL FIELD
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextFormField(
                  controller: emailC,
                  style: const TextStyle(color: Colors.white),
                  decoration: AppTheme.inputDecoration(
                    hint: "Enter your Email",
                    suffix: const Icon(Icons.email_outlined,
                        color: Colors.white54),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// SHOW PASSWORD FIELDS ONLY AFTER "NEXT"
              if (showPasswordFields) ...[
                // Password
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextFormField(
                    controller: passC,
                    obscureText: obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: AppTheme.inputDecoration(
                      hint: existingUser
                          ? "Enter Password"
                          : "Create Password",
                      suffix: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                        onPressed: () =>
                            setState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Confirm password only for new users
                if (!existingUser)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextFormField(
                      controller: confirmC,
                      obscureText: obscureC,
                      style: const TextStyle(color: Colors.white),
                      decoration: AppTheme.inputDecoration(
                        hint: "Confirm Password",
                        suffix: IconButton(
                          icon: Icon(
                            obscureC
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () =>
                              setState(() => obscureC = !obscureC),
                        ),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 25),

              /// MAIN BUTTON (Next → Login/Create Account)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : (!showPasswordFields
                      ? checkEmail
                      : handleFinalSubmit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(
                    color: Colors.black,
                  )
                      : Text(
                    !showPasswordFields
                        ? "NEXT"
                        : (existingUser
                        ? "LOGIN"
                        : "CREATE ACCOUNT"),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text("OR",
                    style: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 20),

              /// GOOGLE BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : handleGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.account_circle_outlined,
                      color: Colors.white70),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(color: Colors.white70),
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
