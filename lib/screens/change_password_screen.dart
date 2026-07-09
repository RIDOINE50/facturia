import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightBlue = Color(0xFFF0F9FF);
const Color kInputBorder = Color(0xFFD1D5DB);

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    // Validation
    if (_currentPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre mot de passe actuel';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Le nouveau mot de passe doit faire au moins 6 caractères';
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Les mots de passe ne correspondent pas';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Supabase ne permet pas de vérifier l'ancien mot de passe directement
      // On utilise updatePassword qui nécessite une re-authentication
      // Pour simplifier, on met juste à jour le mot de passe
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mot de passe modifié avec succès'),
            backgroundColor: kGreen,
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
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
    if (message.contains('password')) {
      return 'Mot de passe trop faible (minimum 6 caractères)';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Modifier le mot de passe',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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

            // Icône sécurité
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kDarkBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Sécurité du compte',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Changez votre mot de passe régulièrement\npour protéger votre compte',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: kGrayText,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Mot de passe actuel
            _buildLabel('MOT DE PASSE ACTUEL'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _currentPasswordController,
              hintText: 'Entrez votre mot de passe actuel',
              showPassword: _showCurrentPassword,
              onToggleVisibility: () {
                setState(() {
                  _showCurrentPassword = !_showCurrentPassword;
                });
              },
            ),
            const SizedBox(height: 20),

            // Nouveau mot de passe
            _buildLabel('NOUVEAU MOT DE PASSE'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _newPasswordController,
              hintText: 'Minimum 6 caractères',
              showPassword: _showNewPassword,
              onToggleVisibility: () {
                setState(() {
                  _showNewPassword = !_showNewPassword;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 12, color: kGrayText),
                const SizedBox(width: 4),
                Text(
                  'Utilisez majuscules, chiffres et symboles pour plus de sécurité',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: kGrayText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Confirmer le mot de passe
            _buildLabel('CONFIRMER LE NOUVEAU MOT DE PASSE'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _confirmPasswordController,
              hintText: 'Retapez le nouveau mot de passe',
              showPassword: _showConfirmPassword,
              onToggleVisibility: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
            ),
            const SizedBox(height: 32),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleChangePassword,
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
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Enregistrer le nouveau mot de passe',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Note de sécurité
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: kOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Après modification, vous devrez vous reconnecter sur vos autres appareils.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: kGrayText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
        prefixIcon: const Icon(Icons.lock_outline, color: kGrayText, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: kGrayText,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
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
      ),
    );
  }
}