import 'package:flutter/material.dart';
import 'package:ott_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🔹 remove all saved data

    // 🔹 Navigate to login screen and remove all previous routes
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage('assets/user.jpg'), // replace with your image
                  ),
                  Positioned(
                    bottom: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 16,
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Alexandar Golap",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "username@website.com",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Get Premium!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(Icons.person, "Edit profile"),
              _buildMenuItem(Icons.notifications_none, "Notification"),
              _buildMenuItem(Icons.download, "Download"),
              _buildMenuItem(Icons.security, "Security"),
              _buildMenuItem(Icons.language, "Language", trailing: "English (India)"),
              _buildMenuItem(Icons.help_outline, "Help Center"),
              _buildMenuItem(Icons.privacy_tip_outlined, "Privacy Policy"),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => _logout(context), // 🔹 call logout
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMenuItem(IconData icon, String title, {String? trailing}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing != null
          ? Text(trailing, style: const TextStyle(color: Colors.white70))
          : const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      onTap: () {},
    );
  }
}
