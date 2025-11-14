import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color limeColor = Color(0xFFB6FF3B);

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // Load Firestore Data
  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();

    usernameController.text = doc["firstName"] ?? "";
    emailController.text = doc["email"] ?? "";
    phoneController.text = doc["phone"] ?? "";
  }

  // ASK USER FOR OLD PASSWORD POPUP
  Future<String?> askOldPassword() async {
    TextEditingController oldPass = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Verify Password"),
          content: TextField(
            controller: oldPass,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Enter old password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, oldPass.text.trim());
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  // RE-AUTHENTICATE USER
  Future<bool> reAuthenticateUser(String email, String password) async {
    try {
      AuthCredential credential =
      EmailAuthProvider.credential(email: email, password: password);

      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithCredential(credential);

      return true;
    } catch (e) {
      return false;
    }
  }

  // UPDATE PROFILE FUNCTION
  Future<void> updateProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    String username = usernameController.text.trim();
    String newEmail = emailController.text.trim();
    String phone = phoneController.text.trim();
    String newPassword = passwordController.text.trim();

    try {
      // Check Google OR Email/Password login
      String provider = user.providerData[0].providerId;

      // ONLY Email/Password users need re-auth
      if (provider == "password") {
        // Ask for old password
        String? oldPassword = await askOldPassword();
        if (oldPassword == null || oldPassword.isEmpty) return;

        // Re-authenticate
        bool isVerified =
        await reAuthenticateUser(user.email!, oldPassword);

        if (!isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Old password incorrect"),
            backgroundColor: Colors.red,
          ));
          return;
        }

        // Update Email
        if (newEmail.isNotEmpty && newEmail != user.email) {
          await user.updateEmail(newEmail);
        }

        // Update Password
        if (newPassword.isNotEmpty) {
          await user.updatePassword(newPassword);
        }
      }

      // ALWAYS Update Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "firstName": username,
        "email": newEmail,
        "phone": phone,
        "updatedAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Profile Updated Successfully"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ));
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
          icon: const Icon(Icons.arrow_back, color: limeColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: limeColor, fontSize: 18),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 30),

            buildLabel("Username"),
            buildTextField(usernameController),
            const SizedBox(height: 15),

            buildLabel("Email"),
            buildTextField(emailController),
            const SizedBox(height: 15),

            buildLabel("Phone Number"),
            buildTextField(phoneController),
            const SizedBox(height: 15),

            buildLabel("New Password"),
            buildTextField(passwordController, obscure: true),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: limeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Update",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(color: limeColor, fontSize: 14),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller,
      {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: limeColor, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          contentPadding:
          EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
