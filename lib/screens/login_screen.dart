import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'register_step1_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';
import 'admin/admin_main_screen.dart';
// Couleurs exactes du design
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightGray = Color(0xFFE5E7EB);
const Color kInputBg = Color(0xFFF9FAFB);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

    Future<void> _handleLogin() async {
    // Validation
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre email';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre mot de passe';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Connexion via Supabase
      final response = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        print('✅ Connecté avec succès : ${response.user!.email}');
        
        // 2. VÉRIFIER LE RÔLE ICI ⬇️
        final bool isAdmin = await AuthService.isAdmin();
        print('👉 Est-ce un admin ? $isAdmin');
        
        if (mounted) {
          // 3. Rediriger selon le rôle
          if (isAdmin) {
            Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (context) => const AdminMainScreen()),
  (route) => false,
);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          }
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion : $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    } else if (message.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre email';
    } else if (message.contains('Too many requests')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOGO FACTURIA
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined, color: kDarkBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Factu',
                          style: GoogleFonts.novaFlat(fontSize: 24, color: kDarkBlue),
                        ),
                        TextSpan(
                          text: 'RIA',
                          style: GoogleFonts.novaFlat(fontSize: 24, color: kOrange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // TITRE
              Text(
                'Bon retour 👋',
                style: GoogleFonts.novaFlat(fontSize: 32, color: kDarkBlue),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecte-toi à ton espace',
                style: GoogleFonts.inter(fontSize: 15, color: kGrayText),
              ),
              const SizedBox(height: 32),

              // MESSAGE D'ERREUR
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // CHAMP EMAIL / TÉLÉPHONE
              _buildLabel('Email ou téléphone'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'kofi@gmail.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // CHAMP MOT DE PASSE
              _buildLabel('Mot de passe'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 12),

              // MOT DE PASSE OUBLIÉ
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Mot de passe oublié ?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: kDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // BOUTON SE CONNECTER
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Se connecter',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // SÉPARATEUR "OU"
              Row(
                children: [
                  const Expanded(child: Divider(color: kLightGray, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ou', style: GoogleFonts.inter(fontSize: 13, color: kGrayText)),
                  ),
                  const Expanded(child: Divider(color: kLightGray, thickness: 1)),
                ],
              ),
              const SizedBox(height: 32),

              // BOUTON GOOGLE
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connexion Google à venir'),
                        backgroundColor: kGrayText,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kLightGray),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: kDarkBlue),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continuer avec Google',
                        style: GoogleFonts.inter(fontSize: 15, color: kDarkBlue, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // CRÉER UN COMPTE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ?',
                    style: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterStep1Screen()),
                      );
                    },
                    child: Text(
                      'Créer un compte',
                      style: GoogleFonts.inter(fontSize: 14, color: kDarkBlue, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS RÉUTILISABLES POUR LE DESIGN ---

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF111827), fontWeight: FontWeight.w500),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
        prefixIcon: Icon(icon, color: kGrayText, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: kGrayText,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: kInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDarkBlue, width: 2),
        ),
      ),
    );
  }
}