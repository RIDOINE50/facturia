import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'register_step3_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGrayText = Color(0xFF6B7280);
const Color kInputBorder = Color(0xFFD1D5DB);
const Color kLightBlue = Color(0xFFF0F9FF);

class RegisterStep2Screen extends StatefulWidget {
  final String userId;

  const RegisterStep2Screen({super.key, required this.userId});

  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  final _companyNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ifuController = TextEditingController();
  
  String _selectedSector = 'Freelance / Design';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameController.dispose();
    _cityController.dispose();
    _ifuController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    // Validation
    if (_companyNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer le nom de votre entreprise';
      });
      return;
    }

    if (_cityController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre ville';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sauvegarder les infos de l'entreprise dans Supabase
      await AuthService.completeProfile(
        userId: widget.userId,
        companyName: _companyNameController.text.trim(),
        sector: _selectedSector,
        city: _cityController.text.trim(),
        ifuNif: _ifuController.text.trim().isEmpty ? null : _ifuController.text.trim(),
      );

      print('✅ Infos entreprise sauvegardées');
      
      // Passer à l'étape 3
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterStep3Screen(userId: widget.userId),
          ),
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
                  'Ton entreprise 🏢',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ces infos apparaîtront sur tes factures',
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
                      'Étape 2 sur 3 — Profil entreprise',
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
                              color: kInputBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Upload Logo
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: kDarkBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _companyNameController.text.isNotEmpty
                                        ? _companyNameController.text.substring(0, 2).toUpperCase()
                                        : 'KD',
                                    style: GoogleFonts.novaFlat(fontSize: 28, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt, size: 12, color: kDarkBlue),
                              const SizedBox(width: 4),
                              Text(
                                'Ajouter un logo',
                                style: GoogleFonts.inter(fontSize: 13, color: kDarkBlue, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Champ Nom de l'entreprise
                    _buildLabel('NOM DE L\'ENTREPRISE'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _companyNameController,
                      hintText: 'Kofi Design Studio',
                    ),
                    const SizedBox(height: 20),

                    // Champ Secteur d'activité
                    _buildLabel('SECTEUR D\'ACTIVITÉ'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: kLightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kInputBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSector,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: kGrayText),
                          items: const [
                            DropdownMenuItem(value: 'Freelance / Design', child: Text('Freelance / Design')),
                            DropdownMenuItem(value: 'Commerce', child: Text('Commerce')),
                            DropdownMenuItem(value: 'Services', child: Text('Services')),
                            DropdownMenuItem(value: 'Artisanat', child: Text('Artisanat')),
                            DropdownMenuItem(value: 'Technologie', child: Text('Technologie')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSector = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Champ Ville
                    _buildLabel('VILLE'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _cityController,
                      hintText: 'Cotonou, Bénin',
                    ),
                    const SizedBox(height: 20),

                    // Champ IFU / NIF
                    _buildLabel('IFU / NIF (OPTIONNEL)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _ifuController,
                      hintText: 'Numéro fiscal si disponible',
                    ),
                    const SizedBox(height: 32),

                    // Bouton Suivant
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleNext,
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
  }) {
    return TextField(
      controller: controller,
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
      ),
    );
  }
}