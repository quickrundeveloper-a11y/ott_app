import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ott_app/screens/complete_profile_screen.dart';
import 'package:ott_app/screens/home_screen.dart';
import 'package:ott_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCm6VK_CNVZnPoJkolF4u8rEBw4l21o4oc",
          appId: "1:578839911643:android:8c34afb687a643857140fe",
          messagingSenderId: "578839911643",
          projectId: "ott-app-a3eaf",
          storageBucket: "ott-app-a3eaf.firebasestorage.app",
        ),
      );
    }
  } catch (e) {
    // show or log if needed, but continue.
    // print('Firebase init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// We'll check SharedPreferences + Firebase to decide the first screen
class _MyAppState extends State<MyApp> {
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    // Default to login while checking
    Widget start = const LoginScreen();

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('isLoggedIn') ?? false;

      final user = FirebaseAuth.instance.currentUser;

      // If we have a saved flag AND a firebase user (token), prefer that
      if (saved && user != null) {
        // check if user doc exists in Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          start = const HomeScreen();
        } else {
          start = CompleteProfileScreen(
            // send args if needed; CompleteProfileScreen expects ModalRoute args in our implementation.
            // We'll push replacement with arguments later where used. For simplicity, we'll just show the screen.
          );
        }
      } else if (user != null && !saved) {
        // No pref but Firebase has user (possible after cold restart). Use Firestore check.
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          start = const HomeScreen();
        } else {
          start = CompleteProfileScreen();
        }
      } else {
        // fallback: show login screen
        start = const LoginScreen();
      }
    } catch (e) {
      // ignore and show login
      start = const LoginScreen();
    }

    if (mounted) setState(() => _startScreen = start);
  }

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFB6FF3B);
    final colorScheme = ColorScheme.fromSeed(seedColor: lime, brightness: Brightness.dark);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OTT App',
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
      // If _startScreen is null we are still checking: show a quick splash
      home: _startScreen ?? const SplashScreen(),
      routes: {
        '/': (_) => const LoginScreen(),
        HomeScreen.route: (_) => const HomeScreen(),
        CompleteProfileScreen.route: (_) => const CompleteProfileScreen(),
      },
    );
  }
}

/// Simple splash while main decides where to go
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFB6FF3B);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading...', style: TextStyle(color: lime)),
        ]),
      ),
    );
  }
}
