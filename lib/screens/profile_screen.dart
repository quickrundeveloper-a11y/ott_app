import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ott_app/screens/Change_password.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../theme/theme.dart';
import 'login_screen.dart';
import 'policy.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = "";
  String lastName = "";
  String email = "";
  String profileImage = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // ---------------- LOAD USER DATA FROM FIRESTORE ----------------
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("uid"); // stored at login

    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }

    final userDoc =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;

      setState(() {
        firstName = data["firstName"] ?? "";
        lastName = data["lastName"] ?? "";
        email = data["email"] ?? "";
        profileImage = data["profileImage"] ??
            ""; // Firebase storage URL OR empty (if none)
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // ----------------- LOGOUT -----------------
  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: AppTheme.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ---------------- MAIN BODY ----------------
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.textWhite),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              // ---------------- PROFILE AVATAR ----------------
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.cardDark,
              child: const Icon(
                Icons.person,
                color: AppTheme.textLight,
                size: 55,
              ),
            ),


              const SizedBox(height: 16),

              // ---------------- NAME ----------------
              Text(
                "$firstName $lastName",
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // ---------------- EMAIL ----------------
              Text(
                email,
                style:
                const TextStyle(color: AppTheme.textLight, fontSize: 14),
              ),

              const SizedBox(height: 30),

              // ---------------- MENU ITEMS ----------------
              _buildMenuItem(Icons.lock_outline, "Change Password", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage()),
                );
              }),

              _buildMenuItem(Icons.language, "Language",
                  trailing: "English (India)"),

              _buildMenuItem(Icons.privacy_tip_outlined, "Privacy Policy",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage()),
                    );
                  }),

              const SizedBox(height: 20),

              // ---------------- LOGOUT ----------------
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.greenAccent),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: AppTheme.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _logout(context),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- MENU ITEM BUILDER -----------------
  static Widget _buildMenuItem(
      IconData icon,
      String title, {
        String? trailing,
        VoidCallback? onTap,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.greenAccent),
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.textWhite),
        ),
        trailing: trailing != null
            ? Text(
          trailing,
          style: const TextStyle(color: AppTheme.textLight),
        )
            : const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textGrey),
        onTap: onTap,
      ),
    );
  }
}
