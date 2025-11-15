import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ott_app/screens/profile_screen.dart';

import '../theme/theme.dart';


class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController oldPass = TextEditingController();
  final TextEditingController newPass = TextEditingController();
  final TextEditingController confirmPass = TextEditingController();

  bool oldVisible = false;
  bool newVisible = false;
  bool confirmVisible = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔥 CHECK WHICH PROVIDER USER USED
    final provider = user?.providerData.isNotEmpty == true
        ? user!.providerData[0].providerId
        : "password";

    final isEmailUser = provider == "password";

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.greenAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(color: AppTheme.greenAccent, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: isEmailUser
            ? buildPasswordUI(context, user!)
            : buildGoogleBlockedUI(), // Google login cannot change password
      ),
    );
  }

  // ❌ GOOGLE BLOCKED SCREEN
  Widget buildGoogleBlockedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: AppTheme.greenAccent, size: 60),
          const SizedBox(height: 20),
          const Text(
            "Password change not available\nfor Google login users.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textLight, fontSize: 18),
          ),
        ],
      ),
    );
  }

  // ✅ EMAIL/PASSWORD USERS CAN CHANGE PASSWORD
  Widget buildPasswordUI(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        buildLabel("Old Password"),
        buildPasswordField(
          controller: oldPass,
          visible: oldVisible,
          onToggle: () => setState(() => oldVisible = !oldVisible),
        ),

        const SizedBox(height: 20),

        buildLabel("New Password"),
        buildPasswordField(
          controller: newPass,
          visible: newVisible,
          onToggle: () => setState(() => newVisible = !newVisible),
        ),

        const SizedBox(height: 20),

        buildLabel("Confirm Password"),
        buildPasswordField(
          controller: confirmPass,
          visible: confirmVisible,
          onToggle: () => setState(() => confirmVisible = !confirmVisible),
        ),

        const SizedBox(height: 35),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenAccent,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onPressed: () => updatePassword(user),
            child: const Text("Save Password"),
          ),
        ),
      ],
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppTheme.textLight),
    );
  }

  // Reusable password field
  Widget buildPasswordField({
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        style: const TextStyle(color: AppTheme.textWhite),
        decoration: AppTheme.inputDecoration(
          suffix: IconButton(
            onPressed: onToggle,
            icon: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 MAIN LOGIC: UPDATE PASSWORD
  Future<void> updatePassword(User user) async {
    if (oldPass.text.isEmpty ||
        newPass.text.isEmpty ||
        confirmPass.text.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (newPass.text != confirmPass.text) {
      showMessage("New password and confirmation must match");
      return;
    }

    try {
      // 1️⃣ Re-authenticate user
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      // 2️⃣ Update password
      await user.updatePassword(newPass.text.trim());

      showMessage("Password Updated Successfully!");

      // 3️⃣ Redirect to Profile Page
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.pop(context);

        }
      });

    } catch (e) {
      showMessage("Error: ${e.toString()}");
    }
  }


  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.cardDark,
        content: Text(msg, style: const TextStyle(color: AppTheme.textWhite)),
      ),
    );
  }
}
