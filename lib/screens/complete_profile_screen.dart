import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'auth_service.dart';
import 'home_screen.dart';

  // ✔ REQUIRED IMPORT (Fix)

class CompleteProfileArgs {
  final String uid;
  final String? email;
  CompleteProfileArgs({required this.uid, this.email});
}

class CompleteProfileScreen extends StatefulWidget {
  static const route = '/complete-profile';
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  DateTime? _dob;
  String _gender = 'male';
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.greenAccent,
              onPrimary: Colors.white,
              surface: AppTheme.cardDark,
            ),
            dialogBackgroundColor: AppTheme.cardDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _dob == null) return;

    setState(() => _saving = true);

    try {
      final args = ModalRoute.of(context)!.settings.arguments as CompleteProfileArgs;

      await _authService.saveProfile(
        uid: args.uid,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        dob: _dob!,
        gender: _gender,
        email: args.email,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, HomeScreen.route);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Complete your Profile',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text('Tell us about you',
                    style: TextStyle(
                        color: AppTheme.greenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),

                /// FIRST NAME
                TextFormField(
                  controller: _first,
                  style: const TextStyle(color: Colors.white),
                  decoration: AppTheme.inputDecoration(hint: 'First Name'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                /// LAST NAME
                TextFormField(
                  controller: _last,
                  style: const TextStyle(color: Colors.white),
                  decoration: AppTheme.inputDecoration(hint: 'Last Name'),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                /// DOB PICKER
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(14),
                      color: AppTheme.cardDark,
                    ),
                    child: Text(
                      _dob == null
                          ? 'Date of Birth'
                          : '${_dob!.day.toString().padLeft(2, '0')}/'
                          '${_dob!.month.toString().padLeft(2, '0')}/'
                          '${_dob!.year}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// GENDER SELECT
                const Text('Gender',
                    style: TextStyle(color: AppTheme.textLight)),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Radio<String>(
                      value: 'male',
                      groupValue: _gender,
                      activeColor: AppTheme.greenAccent,
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const Text('Male', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 18),
                    Radio<String>(
                      value: 'female',
                      groupValue: _gender,
                      activeColor: AppTheme.greenAccent,
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const Text('Female', style: TextStyle(color: Colors.white)),
                  ],
                ),

                const SizedBox(height: 22),

                /// SAVE BUTTON
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenAccent,
                      foregroundColor: AppTheme.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                        : const Text('Save & Continue',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
