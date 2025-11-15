import 'package:flutter/material.dart';

class AppTheme {
  // Main Accent Color (Your Green)
  static const Color greenAccent = Colors.greenAccent;

  // Background Colors
  static const Color background = Colors.black;
  static const Color cardDark = Color(0xFF1B1B1B);
  static const Color cardDarker = Color(0xFF1A1A1A);

  // Text Colors
  static const Color textWhite = Colors.white;
  static const Color textLight = Colors.white70;
  static const Color textGrey = Colors.grey;

  // Borders
  static const Color borderColor = Colors.white24;

  // Input Decorations
  static InputDecoration inputDecoration({
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  // Default App ThemeData (Optional)
  static ThemeData mainTheme() {
    return ThemeData(
      scaffoldBackgroundColor: background,
      fontFamily: "Ballu bhai 2",
      primaryColor: greenAccent,
      colorScheme: const ColorScheme.dark(
        primary: greenAccent,
        secondary: greenAccent,
      ),
    );
  }
}
