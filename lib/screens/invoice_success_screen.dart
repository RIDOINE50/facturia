import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_data.dart';
import '../services/pdf_service.dart';
import '../services/data_service.dart';
import 'dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);

class InvoiceSuccessScreen extends StatefulWidget {
  final InvoiceData invoiceData;
  final String invoiceId;

  const InvoiceSuccessScreen({
    super.key,
    required this.invoiceData,
    required this.invoiceId,
  });

  @override
  State<InvoiceSuccessScreen> createState() => _InvoiceSuccessScreenState();
}

class _InvoiceSuccessScreenState extends State<InvoiceSuccessScreen> {
  File? _pdfFile;
  bool _isGeneratingPdf = true;
  Map<String, dynamic>? _company;
  Map<String, dynamic>? _client;

  @override
  void initState() {
    super.initState();
    _loadDataAndGeneratePdf();
  }

  Future<void> _loadDataAndGeneratePdf() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isGeneratingPdf = false);
      return;
    }

    // Vérifier que clientId existe
    if (widget.invoiceData.clientId == null) {
      print('❌ ClientId manquant');
      setState(() => _isGeneratingPdf = false);
      return;
    }

    try {
      // Charger les données
      final company = await DataService.getCompany(user.id);
      
      // Charger le client
      final clientResponse = await Supabase.instance.client
          .from('clients')
          .select()
          .eq('id', widget.invoiceData.clientId!)
          .maybeSingle();

      setState(() {
        _company = company;
        _client = clientResponse;
      });

      // Générer le PDF
      final pdfFile = await PdfService.generateInvoicePdf(
        invoiceData: widget.invoiceData,
        companyName: company?['name'] ?? 'Mon Entreprise',
        companyPhone: company?['mobile_money_number'] ?? '',
        companyEmail: user.email ?? '',
        companyAddress: company?['city'] ?? '',
        companyIfu: company?['ifu_nif'] ?? '',
        clientName: _client?['name'] ?? widget.invoiceData.clientName,
        clientPhone: _client?['phone'] ?? '',
        clientEmail: _client?['email'] ?? '',
        clientAddress: _client?['address'] ?? '',
      );

      setState(() {
        _pdfFile = pdfFile;
        _isGeneratingPdf = false;
      });
    } catch (e) {
      print('❌ Erreur génération PDF : $e');
      setState(() => _isGeneratingPdf = false);
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  Future<void> _downloadPDF() async {
    if (_pdfFile == null) return;

    try {
      // Sur Windows/Chrome, on ouvre le dossier
      final uri = Uri.file(_pdfFile!.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📄 PDF sauvegardé : ${_pdfFile!.path}'),
            backgroundColor: kGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur téléchargement : $e');
    }
  }

  Future<void> _shareWhatsApp() async {
    if (_pdfFile == null) return;

    final message = '''
Bonjour ${widget.invoiceData.clientName},

Veuillez trouver ci-joint votre facture ${widget.invoiceData.invoiceNumber} d'un montant de ${_formatAmount(widget.invoiceData.totalAmount)} FCFA.

Merci de votre confiance !
''';

    try {
      // Partager le PDF via WhatsApp
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        text: message,
      );
    } catch (e) {
      print('❌ Erreur partage : $e');
      
      // Fallback : juste le texte
      final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _shareEmail() async {
    if (_pdfFile == null) return;

    final subject = 'Facture ${widget.invoiceData.invoiceNumber}';
    final body = '''
Bonjour ${widget.invoiceData.clientName},

Veuillez trouver ci-joint votre facture ${widget.invoiceData.invoiceNumber} d'un montant de ${_formatAmount(widget.invoiceData.totalAmount)} FCFA.

Cordialement
''';

    try {
      // Partager le PDF via email
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        text: body,
        subject: subject,
      );
    } catch (e) {
      print('❌ Erreur email : $e');
      
      // Fallback : juste le texte
      final url = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header vert
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Facture créée ! 🎉',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.invoiceData.invoiceNumber,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Récapitulatif
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          const SizedBox(height: 16),
                          _buildRecapRow('Client', widget.invoiceData.clientName),
                          _buildRecapRow('Montant', '${_formatAmount(widget.invoiceData.totalAmount)} FCFA'),
                          _buildRecapRow('Articles', '${widget.invoiceData.items.length} article${widget.invoiceData.items.length > 1 ? 's' : ''}'),
                          if (widget.invoiceData.applyTva)
                            _buildRecapRow('TVA', '${_formatAmount(widget.invoiceData.tvaAmount)} FCFA'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Text(
                      'ACTIONS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kGrayText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Télécharger PDF
                    _buildActionButton(
                      icon: Icons.download,
                      title: 'Télécharger le PDF',
                      subtitle: _isGeneratingPdf
                          ? 'Génération en cours...'
                          : _pdfFile != null
                              ? 'Format professionnel prêt à envoyer'
                              : 'Erreur de génération',
                      color: kDarkBlue,
                      isLoading: _isGeneratingPdf,
                      onTap: _isGeneratingPdf ? null : _downloadPDF,
                    ),
                    const SizedBox(height: 12),

                    // WhatsApp
                    _buildActionButton(
                      icon: Icons.chat,
                      title: 'Envoyer par WhatsApp',
                      subtitle: 'Partager le PDF via WhatsApp',
                      color: const Color(0xFF25D366),
                      isLoading: _isGeneratingPdf,
                      onTap: _isGeneratingPdf ? null : _shareWhatsApp,
                    ),
                    const SizedBox(height: 12),

                    // Email
                    _buildActionButton(
                      icon: Icons.email,
                      title: 'Envoyer par email',
                      subtitle: 'Partager le PDF par email',
                      color: Colors.blue,
                      isLoading: _isGeneratingPdf,
                      onTap: _isGeneratingPdf ? null : _shareEmail,
                    ),
                    const SizedBox(height: 24),

                    // Retour dashboard
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const DashboardScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.home, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Retour au tableau de bord',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: kGrayText)),
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

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: kGrayText),
                    ),
                  ],
                ),
              ),
              if (!isLoading) const Icon(Icons.chevron_right, color: kGrayText),
            ],
          ),
        ),
      ),
    );
  }
}