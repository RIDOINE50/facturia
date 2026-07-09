import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rgailzgewvioocdenmwds.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJnYWlsemdldmlvb2NkZW5td2RzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5ODYyMTAsImV4cCI6MjA5NzU2MjIxMH0.2GUEuOwHUB4yx2lHFIk9WmLV-P6gQWZd8ZzUjBIcaaw',
  );

  runApp(const FacturIAApp());
}

class FacturIAApp extends StatelessWidget {
  const FacturIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FacturIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      home: const SplashScreen(),
    );
  }
}