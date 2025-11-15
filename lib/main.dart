import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/UsageTimeService.dart';
import 'dart:io';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger .env
  await dotenv.load(fileName: ".env");

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    final ref = FirebaseStorage.instance.ref();
    print("✅ Firebase Storage connecté : ${ref.fullPath}");
  } catch (e) {
    print("❌ Erreur Firebase Storage : $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late UsageTimeService usageService;

  @override
  void initState() {
    super.initState();

    usageService = UsageTimeService();

    // ⚠️ Avertissement 15 min avant la limite
    usageService.onWarning15min = () {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text("Limite proche"),
          content: const Text(
            "Tu approches de la limite quotidienne d'utilisation.\n"
                "L’application se fermera dans 15 minutes.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            )
          ],
        ),
      );
    };

    // ❌ Fermeture automatique à 4 heures
    usageService.onLimitReached = () {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text("Temps atteint"),
          content: const Text(
            "Tu as atteint la limite quotidienne de 4 heures.\n"
                "L’application va maintenant se fermer.",
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        exit(0);
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Connecty',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
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
      ),
      home: const LoginPage(),
    );
  }
}
