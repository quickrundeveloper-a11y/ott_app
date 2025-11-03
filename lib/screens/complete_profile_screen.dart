   import 'package:flutter/material.dart';

import '../auth_service.dart';
import 'home_screen.dart';

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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFB6FF3B),
            ),
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
    const lime = Color(0xFFB6FF3B);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your Profile'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text('Tell us about you',
                    style: TextStyle(color: lime, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _first,
                  decoration: const InputDecoration(hintText: 'First Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _last,
                  decoration: const InputDecoration(hintText: 'Last Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(hintText: 'Date of Birth'),
                    child: Text(
                      _dob == null
                          ? 'Tap to choose'
                          : '${_dob!.day.toString().padLeft(2, '0')}/'
                          '${_dob!.month.toString().padLeft(2, '0')}/'
                          '${_dob!.year}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Gender', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Radio<String>(
                      value: 'male',
                      groupValue: _gender,
                      activeColor: lime,
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const Text('Male'),
                    const SizedBox(width: 18),
                    Radio<String>(
                      value: 'female',
                      groupValue: _gender,
                      activeColor: lime,
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const Text('Female'),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save & Continue',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
