import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Charger les variables d'environnement avec gestion d'erreur
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env chargé avec succès');
  } catch (e) {
    print('⚠️ .env non trouvé dans l\'APK');
    // Valeurs par défaut pour que l'app ne crash pas
  dotenv.env['SUPABASE_URL'] = '';
dotenv.env['SUPABASE_ANON_KEY'] = '';
dotenv.env['GROQ_API_KEY'] = '';
  }

  // 2. Initialiser Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 3. Lancer l'application (sans DevicePreview)
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