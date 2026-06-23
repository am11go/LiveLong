import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:livelong_flutter/home.dart';
import 'package:livelong_flutter/meal.dart';
import 'onboarding_screen.dart';
import 'meal_page.dart';
import 'workout_page.dart';
import 'progress_tracking_page.dart';
import 'package:provider/provider.dart';
import 'progress_tracking_provider.dart';
import 'home.dart';
import 'admin_login_page.dart';
import 'loginpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProgressTrackingProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/admin': (context) => const AdminLoginPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in, show main shell with bottom navigation on all pages
          return const MainShell();
        }

        // User is not logged in, show onboarding or login
        return const OnboardingScreen();
      },
    );
  }
}
