import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Keep your current import path for login screen.
// If you moved files to /screens, change imports accordingly.
import 'package:ott_app/screens/login_screen.dart';
import 'package:ott_app/screens/home_screen.dart';
import 'package:ott_app/screens/complete_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Using your inline FirebaseOptions is OK.
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCm6VK_CNVZnPoJkolF4u8rEBw4l21o4oc",
      appId: "1:578839911643:android:8c34afb687a643857140fe",
      messagingSenderId: "578839911643",
      projectId: "ott-app-a3eaf",
      storageBucket: "ott-app-a3eaf.firebasestorage.app",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Neon lime accent, dark theme like your design
    const lime = Color(0xFFB6FF3B);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: lime,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth Flow',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.black,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: lime, width: 1.6),
          ),
          hintStyle: const TextStyle(color: Color(0xFFBEBEBE)),
          labelStyle: const TextStyle(color: Color(0xFFE8E8E8)),
        ),
      ),
      // Start at the login screen
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        HomeScreen.route: (_) => const HomeScreen(),
        CompleteProfileScreen.route: (_) => const CompleteProfileScreen(),
      },
    );
  }
}
