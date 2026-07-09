import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightBlue = Color(0xFFF0F9FF);

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mon abonnement',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // PLAN ACTUEL
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan actuel',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Pro',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kOrange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '7 000 FCFA/mois',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Avantages
                  _buildAdvantage('Factures illimitées'),
                  const SizedBox(height: 8),
                  _buildAdvantage('Assistant IA illimité'),
                  const SizedBox(height: 8),
                  _buildAdvantage('Multi-utilisateurs (2)'),
                  const SizedBox(height: 8),
                  _buildAdvantage('Relances automatiques'),
                  const SizedBox(height: 8),
                  _buildAdvantage('Statistiques avancées'),
                  const SizedBox(height: 20),
                  // Prochain renouvellement
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Prochain renouvellement : 20 juillet 2026',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // BOUTON CHANGER DE PLAN
            // ==========================================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.swap_horiz, color: kDarkBlue),
                label: Text(
                  'Changer de plan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kDarkBlue,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kDarkBlue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ==========================================
            // HISTORIQUE DES PAIEMENTS
            // ==========================================
            Text(
              'HISTORIQUE DES PAIEMENTS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kGrayText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildPaymentHistoryItem(
                    'Plan Pro · Juin 2026',
                    'Via MTN Mobile Money',
                    '7 000 F',
                    kGreen,
                  ),
                  Divider(height: 1, color: Colors.grey.shade200, indent: 16),
                  _buildPaymentHistoryItem(
                    'Plan Pro · Mai 2026',
                    'Via MTN Mobile Money',
                    '7 000 F',
                    kGreen,
                  ),
                  Divider(height: 1, color: Colors.grey.shade200, indent: 16),
                  _buildPaymentHistoryItem(
                    'Plan Starter · Avr 2026',
                    'Via Moov Money',
                    '3 000 F',
                    kGrayText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==========================================
            // UTILISATION CE MOIS
            // ==========================================
            Text(
              'UTILISATION CE MOIS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kGrayText,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildUsageItem('Factures créées', '18', '∞', 0.3),
                  const SizedBox(height: 16),
                  _buildUsageItem('Messages IA', '84', '∞', 0.5),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==========================================
            // BOUTON RÉSILIER
            // ==========================================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Résilier l\'abonnement ?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'Vous perdrez l\'accès aux fonctionnalités Pro à la fin de la période en cours.',
                        style: GoogleFonts.inter(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRed,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Résilier'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.cancel_outlined, color: kRed),
                label: Text(
                  'Résilier l\'abonnement',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kRed,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvantage(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryItem(String title, String subtitle, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt_long,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: kGrayText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(String label, String used, String total, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$used / $total',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: kGrayText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(kDarkBlue),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}