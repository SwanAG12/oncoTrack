import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hawhmiecntmfigpaaaok.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhhd2htaWVjbnRtZmlncGFhYW9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0NDMyMzMsImV4cCI6MjA2NTAxOTIzM30.4x4KUW0hMpAlsa1rZ5YFebdhI-sD7Z4BxEYo3PpU_Ig', // ✅ Replace with your actual anon/public key
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
      home: const LoginPage(),
    );
  }
}


