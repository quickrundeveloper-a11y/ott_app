import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ott_app/screens/complete_profile_screen.dart';
import 'package:ott_app/screens/home_screen.dart';
import 'package:ott_app/screens/login_screen.dart';
import 'package:ott_app/theme/theme.dart';
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
    // ignore init errors for now (or log them)
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    Widget start = const LoginScreen();

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('isLoggedIn') ?? false;
      final user = FirebaseAuth.instance.currentUser;

      if (saved && user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        start = doc.exists ? const HomeScreen() : const CompleteProfileScreen();
      } else if (user != null && !saved) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        start = doc.exists ? const HomeScreen() : const CompleteProfileScreen();
      } else {
        start = const LoginScreen();
      }
    } catch (_) {
      start = const LoginScreen();
    }

    if (mounted) setState(() => _startScreen = start);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OTT App',
      theme: AppTheme.mainTheme(),
      // Use `home` to show the decided start screen (no '/' routes conflict).
      home: _startScreen ?? const SplashScreen(),
      // Do NOT include '/' inside routes when using `home:`
      routes: {
        // '/' : removed to avoid duplicate with `home`
        HomeScreen.route: (_) => const HomeScreen(),
        CompleteProfileScreen.route: (_) => const CompleteProfileScreen(),
      },
    );
  }
}

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
