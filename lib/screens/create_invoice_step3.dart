import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_data.dart';
import '../services/data_service.dart';
import 'dashboard_screen.dart';
import 'invoice_success_screen.dart';
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);

class CreateInvoiceStep3 extends StatefulWidget {
  final InvoiceData invoiceData;

  const CreateInvoiceStep3({super.key, required this.invoiceData});

  @override
  State<CreateInvoiceStep3> createState() => _CreateInvoiceStep3State();
}

class _CreateInvoiceStep3State extends State<CreateInvoiceStep3> {
  bool _isLoading = false;

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

      Future<void> _createInvoice({bool isDraft = false}) async {
    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Déterminer le statut selon isDraft
      final status = isDraft ? 'draft' : 'sent';
      
      // 1. Créer la facture avec le bon statut
      final invoiceId = await DataService.createInvoice(
        userId: user.id,
        clientId: widget.invoiceData.clientId!,
        invoiceNumber: widget.invoiceData.invoiceNumber,
        issueDate: widget.invoiceData.issueDate,
        dueDate: widget.invoiceData.dueDate,
        notes: widget.invoiceData.notes,
        subtotal: widget.invoiceData.subtotal,
        tvaAmount: widget.invoiceData.tvaAmount,
        totalAmount: widget.invoiceData.totalAmount,
        status: status, // ← On passe le bon statut
      );

      if (invoiceId == null) {
        throw Exception('Impossible de créer la facture');
      }

      // 2. Créer les lignes de facture
      if (widget.invoiceData.items.isNotEmpty) {
        await DataService.createInvoiceItems(
          invoiceId: invoiceId,
          items: widget.invoiceData.items.map((item) => item.toMap()).toList(),
        );
      }

      // 3. Afficher le message approprié
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft ? '📝 Brouillon enregistré !' : '✅ Facture envoyée avec succès !'),
            backgroundColor: isDraft ? Colors.orange : kGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // 4. Si c'est une vraie facture (pas brouillon), aller vers l'écran de succès
        if (!isDraft) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => InvoiceSuccessScreen(
                invoiceData: widget.invoiceData,
                invoiceId: invoiceId,
              ),
            ),
            (route) => false,
          );
        } else {
          // Si c'est un brouillon, retourner au dashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('❌ Erreur création facture : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle facture',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Options fiscales et paiement',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: kDarkBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Infos',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kGrayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: kDarkBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Articles',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kGrayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: kDarkBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '3',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Options',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kDarkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Récapitulatif
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RÉCAPITULATIF',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kGrayText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecapRow('Client', widget.invoiceData.clientName),
                        _buildRecapRow('N° Facture', widget.invoiceData.invoiceNumber),
                        _buildRecapRow('Articles', '${widget.invoiceData.items.length} article${widget.invoiceData.items.length > 1 ? 's' : ''}'),
                        if (widget.invoiceData.subject.isNotEmpty)
                          _buildRecapRow('Objet', widget.invoiceData.subject),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fiscalité
                  Text(
                    'FISCALITÉ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kGrayText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appliquer la TVA',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '18% sur le montant HT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: kGrayText,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: widget.invoiceData.applyTva,
                          onChanged: (value) {
                            setState(() {
                              widget.invoiceData.applyTva = value;
                            });
                          },
                          activeColor: kDarkBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mode de paiement
                  Text(
                    'MODE DE PAIEMENT',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kGrayText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPaymentOption('MTN', 'Mobile Money'),
                      const SizedBox(width: 12),
                      _buildPaymentOption('MOOV', 'Money'),
                      const SizedBox(width: 12),
                      _buildPaymentOption('Virement', 'Bancaire'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  Text(
                    'NOTES',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kGrayText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      maxLines: 3,
                      onChanged: (value) {
                        widget.invoiceData.notes = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Paiement sous 30 jours. Merci pour votre confiance.',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total et boutons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kDarkBlue,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sous-total HT',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                    ),
                    Text(
                      '${_formatAmount(widget.invoiceData.subtotal)} FCFA',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.invoiceData.applyTva ? 'TVA 18%' : 'TVA (désactivée)',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                    ),
                    Text(
                      widget.invoiceData.applyTva ? '${_formatAmount(widget.invoiceData.tvaAmount)} FCFA' : '—',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL TTC',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_formatAmount(widget.invoiceData.totalAmount)} FCFA',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _createInvoice(isDraft: true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                                'Brouillon',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _createInvoice(isDraft: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: kDarkBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: kDarkBlue,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Créer la facture',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: kGrayText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String name, String subtitle) {
    bool isSelected = widget.invoiceData.paymentMethod == name;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            widget.invoiceData.paymentMethod = name;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kDarkBlue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kDarkBlue : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isSelected ? Colors.white.withOpacity(0.8) : kGrayText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}