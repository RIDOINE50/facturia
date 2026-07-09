import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'register_step2_screen.dart';
import 'login_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kLightBlue = Color(0xFFF0F9FF);
const Color kGrayText = Color(0xFF6B7280);
const Color kInputBorder = Color(0xFFD1D5DB);

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    // Validation basique
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs obligatoires';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Le mot de passe doit faire au moins 6 caractères';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Créer le compte via Supabase
      final response = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (response.user != null) {
        print('✅ Compte créé avec succès !');
        
        // Stocker l'ID utilisateur pour les étapes suivantes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterStep2Screen(userId: response.user!.id),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur est survenue : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String message) {
    if (message.contains('already registered')) {
      return 'Cet email est déjà utilisé';
    } else if (message.contains('password')) {
      return 'Mot de passe trop faible (minimum 6 caractères)';
    } else if (message.contains('email')) {
      return 'Email invalide';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // HEADER BLEU
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(text: 'Factu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          TextSpan(text: 'RIA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kOrange)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenue 🎉',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crée ton compte gratuitement',
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),

          // CONTENU BLANC
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message d'erreur
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

                    // Progress bar
                    Text(
                      'Étape 1 sur 3 — Informations personnelles',
                      style: GoogleFonts.inter(fontSize: 13, color: kGrayText),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: kDarkBlue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: kInputBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: kInputBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Champ Prénom & Nom
                    _buildLabel('PRÉNOM & NOM'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _firstNameController,
                      hintText: 'Kofi',
                      icon: Icons.person,
                      iconColor: kDarkBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _lastNameController,
                      hintText: 'Mensah',
                      icon: Icons.person_outline,
                      iconColor: kDarkBlue,
                    ),
                    const SizedBox(height: 20),

                    // Champ Email
                    _buildLabel('EMAIL'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'kofi@gmail.com',
                      icon: Icons.email,
                      iconColor: Colors.purple[300]!,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // Champ Téléphone
                    _buildLabel('TÉLÉPHONE'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: '+229 97 00 00 00',
                      icon: Icons.phone,
                      iconColor: Colors.orange,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // Champ Mot de passe
                    _buildLabel('MOT DE PASSE'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Minimum 6 caractères',
                      icon: Icons.lock,
                      iconColor: Colors.orange[700]!,
                      isPassword: true,
                    ),
                    const SizedBox(height: 32),

                    // Bouton Suivant
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Suivant',
                                    style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Déjà inscrit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Déjà inscrit ? ',
                          style: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            'Se connecter',
                            style: GoogleFonts.inter(fontSize: 14, color: kDarkBlue, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kGrayText, letterSpacing: 0.5),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    Color? iconColor,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
        filled: true,
        fillColor: kLightBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDarkBlue, width: 2),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: iconColor ?? kGrayText, size: 20),
        ),
      ),
    );
  }
}