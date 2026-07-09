import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'success_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);
const Color kInputBorder = Color(0xFFD1D5DB);
const Color kLightBlue = Color(0xFFF0F9FF);
const Color kYellowBg = Color(0xFFFEF3C7);

class RegisterStep3Screen extends StatefulWidget {
  final String userId;

  const RegisterStep3Screen({super.key, required this.userId});

  @override
  State<RegisterStep3Screen> createState() => _RegisterStep3ScreenState();
}

class _RegisterStep3ScreenState extends State<RegisterStep3Screen> {
  final _phoneController = TextEditingController();
  String _selectedOperator = 'MTN';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    // Validation
    if (_phoneController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre numéro Mobile Money';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mettre à jour le profil avec les infos Mobile Money
      await AuthService.updateMobileMoney(
        userId: widget.userId,
        operator: _selectedOperator,
        number: _phoneController.text.trim(),
      );

      print('✅ Compte créé avec succès !');
      
      // Aller à l'écran de succès
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessScreen()),
        );
      }
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
                  'Mobile Money 💰',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pour recevoir tes paiements clients',
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
                      'Étape 3 sur 3 — Paiement Mobile Money',
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
                              color: kDarkBlue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Choix opérateur
                    Text(
                      'CHOISIS TON OPÉRATEUR',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kGrayText, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildOperatorCard('MTN', const Color(0xFFFFCC00), 'Mobile Money'),
                        const SizedBox(width: 12),
                        _buildOperatorCard('MOOV', const Color(0xFF0066CC), 'Money'),
                        const SizedBox(width: 12),
                        _buildOperatorCard('CELTIIS', const Color(0xFF00A651), 'Pay'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Champ Numéro
                    Text(
                      'NUMÉRO $_selectedOperator MOBILE MONEY',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kGrayText, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+229 97 12 34 56',
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
                          borderSide: const BorderSide(color: kGreen, width: 2),
                        ),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.check_circle, color: kGreen, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info box jaune
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kYellowBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                            child: const Icon(Icons.info, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ce numéro sera affiché sur tes factures. Tu pourras le modifier plus tard dans les paramètres.',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton Créer mon compte
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
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
                                  const Text('🎉', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Créer mon compte',
                                    style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Conditions
                    Text(
                      'En créant un compte, tu acceptes nos Conditions d\'utilisation et notre Politique de confidentialité',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 11, color: kGrayText, height: 1.5),
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

  Widget _buildOperatorCard(String name, Color color, String subtitle) {
    bool isSelected = _selectedOperator == name;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOperator = name;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : kInputBorder,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : kGrayText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isSelected ? color.withOpacity(0.8) : kGrayText,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: kGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}