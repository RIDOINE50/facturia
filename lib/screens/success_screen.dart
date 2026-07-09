import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'create_invoice_step1.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Cercle vert avec check
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: kGreen.withOpacity(0.5), width: 3),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 56,
                    color: kGreen,
                  ),
                ),
                const SizedBox(height: 32),
                // Titre
                Text(
                  'Compte créé ! 🎉',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Message
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 15, height: 1.6),
                    children: [
                      const TextSpan(text: 'Bienvenue sur ', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'FactuRIA', style: const TextStyle(fontWeight: FontWeight.bold, color: kOrange)),
                      const TextSpan(text: ' !\n', style: TextStyle(color: Colors.white)),
                      const TextSpan(text: 'Tu as 3 factures gratuites ce mois.\n', style: TextStyle(color: Colors.white)),
                      const TextSpan(text: 'C\'est parti !', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Bouton Créer ma première facture
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateInvoiceStep1()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kDarkBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Créer ma première facture',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton Explorer le tableau de bord
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Explorer le tableau de bord',
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Stats en bas - VERSION CORRIGÉE
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBox('3', 'Factures\ngratuites', constraints.maxWidth),
                        _buildDivider(),
                        _buildStatBox('10', 'Messages IA\nofferts', constraints.maxWidth),
                        _buildDivider(),
                        _buildStatBox('0 F', 'Pour\ncommencer', constraints.maxWidth),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String number, String label, double maxWidth) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }
}