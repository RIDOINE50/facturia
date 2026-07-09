import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

// Couleurs du design
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFEA580C);
const Color kLightBlueBg = Color(0xFFF0F4FF);
const Color kLightYellowBg = Color(0xFFFEF3C7);
const Color kLightPinkBg = Color(0xFFFCE7F3);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightGray = Color(0xFFD1D5DB);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'titlePart1': 'Crée tes factures',
      'titlePart2': 'en 30 secondes',
      'description': 'Génère des factures professionnelles en PDF, partage-les sur WhatsApp et suis tes paiements en FCFA — le tout depuis ton téléphone.',
      'bgColor': kLightBlueBg,
      'illustration': const InvoiceIllustration(),
    },
    {
      'titlePart1': 'Ton assistant',
      'titlePart2': 'IA toujours disponible',
      'description': 'Pose des questions sur la TVA, l\'IFU, ou demande-lui de rédiger une description de service professionnelle à ta place.',
      'bgColor': kLightYellowBg,
      'illustration': const AIIllustration(),
    },
    {
      'titlePart1': 'Paiement',
      'titlePart2': 'Mobile Money & partage rapide',
      'description': 'Accepte les paiements MTN, Moov et Celtiis. Envoie tes factures PDF directement sur WhatsApp en un seul tap.',
      'bgColor': kLightPinkBg,
      'illustration': const MobileMoneyIllustration(),
    },
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // PARTIE HAUTE (Fond coloré + Illustration)
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: _slides[_currentPage]['bgColor'] as Color,
              child: Stack(
                children: [
                  // Cercle décoratif en arrière-plan
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Contenu centré
                  Center(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        return _slides[index]['illustration'] as Widget;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PARTIE BASSE (Fond blanc + Texte + Boutons)
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Column(
                  children: [
                    // Pagination (Les petits points)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentPage ? kDarkBlue : kLightGray,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Titre avec deux couleurs
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_slides[_currentPage]['titlePart1']} ',
                            style: GoogleFonts.novaFlat(
                              fontSize: 26,
                              color: kDarkBlue,
                              height: 1.2,
                            ),
                          ),
                          TextSpan(
                            text: _slides[_currentPage]['titlePart2'],
                            style: GoogleFonts.novaFlat(
                              fontSize: 26,
                              color: kOrange,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      _slides[_currentPage]['description'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: kGrayText,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Bouton Suivant / C'est parti
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == 2 ? 'C\'est parti' : 'Suivant',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_currentPage != 2) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bouton Passer
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Passer l\'introduction',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: kGrayText,
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
}

// ==========================================
// ILLUSTRATION 1 : FACTURE (Slide 1)
// ==========================================
class InvoiceIllustration extends StatelessWidget {
  const InvoiceIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Le document rose/violet
        Container(
          width: 100,
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9D5FF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              _buildLine(width: 60),
              const SizedBox(height: 10),
              _buildLine(width: 70),
              const SizedBox(height: 10),
              _buildLine(width: 50),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Badges
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'FAC-2026-001',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: kDarkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 4),
                  Text(
                    'Payée',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLine({required double width}) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ==========================================
// ILLUSTRATION 2 : ASSISTANT IA (Slide 2) ⭐
// ==========================================
class AIIllustration extends StatelessWidget {
  const AIIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ROBOT IA DESSINÉ EN CODE
        _buildRobot(),
        const SizedBox(height: 20),
        // BULLE DE CHAT
        Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assistant IA',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: kDarkBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'La TVA au Bénin est de ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                    ),
                    TextSpan(
                      text: '18%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: kOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: '. Tu dois l\'appliquer si tu es assujetti à la DGI.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                    ),
                  ],
                ),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRobot() {
    return SizedBox(
      width: 120,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Antenne gauche
          Positioned(
            top: 0,
            left: 25,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEC4899),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 3,
                  height: 15,
                  color: const Color(0xFFEC4899),
                ),
              ],
            ),
          ),
          // Antenne droite
          Positioned(
            top: 0,
            right: 25,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEC4899),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 3,
                  height: 15,
                  color: const Color(0xFFEC4899),
                ),
              ],
            ),
          ),
          // Tête du robot (corps principal)
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFE9D5FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFC084FC),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC084FC).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Yeux
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildEye(),
                    const SizedBox(width: 16),
                    _buildEye(),
                  ],
                ),
                const SizedBox(height: 8),
                // Bouche
                Container(
                  width: 30,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC084FC),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          // Oreilles
          Positioned(
            left: 0,
            child: Container(
              width: 12,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 12,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFC084FC),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ILLUSTRATION 3 : MOBILE MONEY (Slide 3)
// ==========================================
class MobileMoneyIllustration extends StatelessWidget {
  const MobileMoneyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Téléphone
        Container(
          width: 90,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLightGray, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icônes opérateurs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOperatorDot(const Color(0xFFFFCC00)),
                  const SizedBox(width: 6),
                  _buildOperatorDot(const Color(0xFF0066CC)),
                  const SizedBox(width: 6),
                  _buildOperatorDot(const Color(0xFF00A651)),
                ],
              ),
              const SizedBox(height: 16),
              // Checkmark
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Payé !',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Badge WhatsApp
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.share, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Text(
                'WhatsApp Share',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatorDot(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}