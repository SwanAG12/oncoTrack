import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_application_1/auth/login_page.dart';
import 'package:flutter_application_1/pages/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hawhmiecntmfigpaaaok.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhhd2htaWVjbnRtZmlncGFhYW9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0NDMyMzMsImV4cCI6MjA2NTAxOTIzM30.4x4KUW0hMpAlsa1rZ5YFebdhI-sD7Z4BxEYo3PpU_Ig',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Schyler'),
      home: const AuthWrapper(),
    );
  }
}

/// This widget decides whether to show Login or Dashboard
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: fb.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to check auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user is logged in, go to dashboard
        if (snapshot.hasData && snapshot.data != null) {
          return HomeDashboard(userID: snapshot.data!.uid);
        }

        // Otherwise show login page
        return const LoginPage();
      },
    );
  }
}
