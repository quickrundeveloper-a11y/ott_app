import 'package:flutter/material.dart';
import 'package:ott_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved user data

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

              // Profile Avatar
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
                      backgroundColor: limeColor,
                      radius: 18,
                      child: const Icon(Icons.edit, color: Colors.black, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Text(
                "Alexandar Golap",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "username@website.com",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Premium Section
              Container(
                decoration: BoxDecoration(
                  color: limeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: limeColor, width: 1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Color(0xFFB6FF3B)),
                        SizedBox(width: 10),
                        Text(
                          "Get Premium!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Menu Items
              _buildMenuItem(Icons.person, "Edit Profile"),
              _buildMenuItem(Icons.notifications_none, "Notifications"),
              _buildMenuItem(Icons.download, "Downloads"),
              _buildMenuItem(Icons.security, "Security"),
              _buildMenuItem(Icons.language, "Language", trailing: "English (India)"),
              _buildMenuItem(Icons.help_outline, "Help Center"),
              _buildMenuItem(Icons.privacy_tip_outlined, "Privacy Policy"),

              const SizedBox(height: 10),

              // Logout Button
              ListTile(
                leading: const Icon(Icons.logout, color: limeColor),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: limeColor, fontWeight: FontWeight.bold),
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

  static Widget _buildMenuItem(IconData icon, String title, {String? trailing}) {
    const limeColor = Color(0xFFB6FF3B);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: limeColor),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        trailing: trailing != null
            ? Text(
          trailing,
          style: const TextStyle(color: Colors.white70),
        )
            : const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () {},
      ),
    );
  }
}
