import 'package:flutter/material.dart';
import 'package:ott_app/screens/login_screen.dart';
import 'package:ott_app/screens/policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profile.dart';
import 'help_center.dart';
import 'notification.dart';
import 'download_page.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
    const limeColor = Color(0xFFB6FF3B);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: limeColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: limeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              Stack(
                alignment: Alignment.center,
                children: [
                  const CircleAvatar(
                    radius: 55,
                    backgroundImage: AssetImage('assets/user.jpg'),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 4,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: limeColor,
                      child: const Icon(Icons.edit, color: Colors.black),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                "Alexandar Golap",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const Text(
                "username@website.com",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 30),

              _buildMenuItem(Icons.person, "Edit Profile", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              }),

              _buildMenuItem(Icons.notifications, "Notifications", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                );
              }),

              _buildMenuItem(Icons.download, "Downloads", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DownloadPage()),
                );
              }),

              _buildMenuItem(Icons.security, "Security"),

              _buildMenuItem(Icons.language, "Language",
                  trailing: "English (India)"),

              _buildMenuItem(Icons.help_outline, "Help Center", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                );
              }),

              // ⭐ FIXED: PRIVACY POLICY NAVIGATION
              _buildMenuItem(Icons.privacy_tip_outlined, "Privacy Policy",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                    );
                  }),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.logout, color: limeColor),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: limeColor,
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

  static Widget _buildMenuItem(
      IconData icon,
      String title, {
        String? trailing,
        VoidCallback? onTap,
      }) {

    const limeColor = Color(0xFFB6FF3B);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: limeColor),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: trailing != null
            ? Text(
          trailing,
          style: const TextStyle(color: Colors.white60),
        )
            : const Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
