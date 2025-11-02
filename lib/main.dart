import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp();
  } else {
    debugPrint('Firebase non initialisé : plateforme non supportée.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Connecty',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A0033),
        primaryColor: const Color(0xFF6A1B9A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A148C),
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
        cardColor: const Color(0xFF2A003F),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 16),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      //home: const HomePage(),
      home: const LoginPage(),
    );
  }
}
