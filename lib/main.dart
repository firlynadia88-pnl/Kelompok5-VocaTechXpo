
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import Splash Screen
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load konfigurasi environment
  await dotenv.load(fileName: '.env');

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://bptllbnxpuglooqdmmyv.supabase.co',
    anonKey: 'sb_publishable_QctjbhHmweqyiB74MLfRuA_Z2Xr-sNR',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VOCA-TECHXPO',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B21A8),
          primary: const Color(0xFF6B21A8),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
