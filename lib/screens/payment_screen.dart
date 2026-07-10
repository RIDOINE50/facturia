import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kkiapay_service.dart';
import 'kkiapay_webview_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPlan = 'starter';
  bool _isProcessing = false;

  final Map<String, Map<String, dynamic>> _plans = {
    'starter': {
      'name': 'Starter',
      'price': 3000,
      'color': kOrange,
      'features': [
        'Factures illimitées',
        'Export PDF pro',
        'Assistant IA (100 messages/mois)',
        'Support email',
      ],
    },
    'pro': {
      'name': 'Pro',
      'price': 7000,
      'color': kDarkBlue,
      'features': [
        'Tout du plan Starter',
        'Multi-utilisateurs',
        'Relances automatiques',
        'Statistiques avancées',
        'Assistant IA illimité',
        'Support prioritaire',
      ],
    },
  };

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isProcessing = false);
      _showError('Vous devez être connecté');
      return;
    }

    final plan = _plans[_selectedPlan]!;
    final amount = plan['price'];
    final transactionId = 'FACTURIA_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 1. Sauvegarder le paiement en attente dans Supabase
      await KKiaPayService.savePendingPayment(
        userId: userId,
        amount: amount,
        plan: _selectedPlan,
        transactionId: transactionId,
      );

      // 2. Générer l'URL de paiement KKiaPay
      final paymentUrl = await KKiaPayService.generatePaymentUrl(
        amount: amount,
        transactionId: transactionId,
        description: 'Abonnement FacturIA - Plan ${plan['name']}',
      );

      if (paymentUrl == null) {
        setState(() => _isProcessing = false);
        _showError('Erreur lors de la génération du lien de paiement');
        return;
      }

      setState(() => _isProcessing = false);

      // 3. Ouvrir l'interface KKiaPay DANS l'application
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KkiapayWebviewScreen(
            paymentUrl: paymentUrl,
            transactionId: transactionId,
          ),
        ),
      );

      // 4. Traiter le résultat quand l'utilisateur revient
      if (result != null && result['status'] == 'SUCCESS') {
        // Le paiement a réussi !
        await KKiaPayService.updatePaymentStatus(
          transactionId: transactionId,
          status: 'success',
        );
        if (mounted) _showSuccess(plan['name']);
      } else {
        // Annulé ou échoué
        if (mounted) {
          _showError('Paiement annulé ou non confirmé. Votre abonnement n\'a pas été activé.');
        }
      }

    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Erreur : $e');
    }
  }

  void _showSuccess(String planName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: kGreen, size: 32),
            const SizedBox(width: 12),
            Text('Paiement réussi !', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Votre abonnement $planName a été activé !',
          style: GoogleFonts.inter(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Text('Erreur', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        title: Text(
          'Choisir un plan',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionnez votre plan',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Paiement sécurisé par Mobile Money',
              style: GoogleFonts.inter(fontSize: 14, color: kGrayText),
            ),
            const SizedBox(height: 32),

            ..._plans.entries.map((entry) {
              final planKey = entry.key;
              final plan = entry.value;
              final isSelected = _selectedPlan == planKey;

              return GestureDetector(
                onTap: () => setState(() => _selectedPlan = planKey),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? plan['color'] : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: planKey,
                            groupValue: _selectedPlan,
                            onChanged: (value) => setState(() => _selectedPlan = value!),
                            activeColor: plan['color'],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan ${plan['name']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${plan['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA / mois',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: plan['color'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...plan['features'].map<Widget>((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: plan['color'], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _plans[_selectedPlan]!['color'],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Payer ${_plans[_selectedPlan]!['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Paiement sécurisé par', style: GoogleFonts.inter(fontSize: 12, color: kGrayText)),
                  const SizedBox(width: 8),
                  Text('KKiaPay', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: kDarkBlue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}