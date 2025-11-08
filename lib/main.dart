import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import généré automatiquement


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Connecty',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white, // Fond clair global
        primaryColor: const Color(0xFF6A1B9A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6A1B9A),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8E24AA),
        ),
        cardColor: Colors.white, // Fond clair pour les cartes
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
          bodyLarge: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      //home: const HomePage(),
      home: const LoginPage(),
      // home: const ProfilePage(),
    );
  }
}
