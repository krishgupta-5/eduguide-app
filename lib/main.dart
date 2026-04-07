import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:eduguide/features/home/screens/splash_screen.dart';
import 'package:eduguide/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check with debug provider for development
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase app already initialized, continue
    } else {
      rethrow;
    }
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
