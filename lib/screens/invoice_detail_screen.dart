import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/data_service.dart';
import '../services/pdf_service.dart';
import '../models/invoice_data.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreen = Color(0xFF10B981);
const Color kOrange = Color(0xFFF59E0B);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightGray = Color(0xFFF3F4F6);

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Map<String, dynamic>? _invoice;
  Map<String, dynamic>? _company;
  Map<String, dynamic>? _client;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  Future<void> _loadInvoiceData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      print('🔍 Chargement facture ID: ${widget.invoiceId}');

      final invoiceResponse = await Supabase.instance.client
          .from('invoices')
          .select('*, clients(*)')
          .eq('id', widget.invoiceId)
          .single();

      final companyResponse = await DataService.getCompany(user.id);

      final itemsResponse = await Supabase.instance.client
          .from('invoice_items')
          .select()
          .eq('invoice_id', widget.invoiceId);

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('logo_url, signature_url, stamp_url')
          .eq('id', user.id)
          .maybeSingle();

      print('🖼️ Logo URL : ${profileResponse?['logo_url']}');
      print('✍️ Signature URL : ${profileResponse?['signature_url']}');
      print('🔏 Stamp URL : ${profileResponse?['stamp_url']}');

      setState(() {
        _invoice = invoiceResponse;
        _company = companyResponse;
        _client = invoiceResponse['clients'];
        _items = List<Map<String, dynamic>>.from(itemsResponse);
        _userProfile = profileResponse;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement facture : $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _downloadPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Génération du PDF...'),
        backgroundColor: kDarkBlue,
      ),
    );

    try {
      print('🔍 Début génération PDF');
      print('🔍 _userProfile: $_userProfile');

      final invoiceData = InvoiceData();
      invoiceData.invoiceNumber = _invoice!['invoice_number'] ?? '';
      invoiceData.issueDate = DateTime.parse(_invoice!['issue_date']);
      invoiceData.dueDate = _invoice!['due_date'] != null ? DateTime.parse(_invoice!['due_date']) : null;
      invoiceData.items = _items.map((item) => InvoiceItem(
        description: item['description'] ?? '',
        quantity: (item['quantity'] as num).toInt(),
        unitPrice: (item['unit_price'] as num).toDouble(),
      )).toList();
      invoiceData.applyTva = (_invoice!['tva_amount'] as num).toDouble() > 0;

      final logoUrl = _userProfile?['logo_url'];
      final signatureUrl = _userProfile?['signature_url'];
      final stampUrl = _userProfile?['stamp_url'];

      print('🖼️ Logo URL passé au PDF : $logoUrl');
      print('✍️ Signature URL passé au PDF : $signatureUrl');
      print('🔏 Stamp URL passé au PDF : $stampUrl');

      final pdfFile = await PdfService.generateInvoicePdf(
        invoiceData: invoiceData,
        companyName: _company!['name'] ?? '',
        companyPhone: _company!['mobile_money_number'] ?? '',
        companyEmail: _company!['email'] ?? '',
        companyAddress: _company!['address'] ?? '',
        companyIfu: _company!['ifu_nif'] ?? '',
        clientName: _client?['name'] ?? '',
        clientPhone: _client?['phone'] ?? '',
        clientEmail: _client?['email'] ?? '',
        clientAddress: _client?['address'] ?? '',
        logoUrl: logoUrl,
        signatureUrl: signatureUrl,
        stampUrl: stampUrl,
      );

      print('✅ PDF généré avec succès : ${pdfFile.path}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF généré : ${pdfFile.path}'),
            backgroundColor: kGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur génération PDF : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
            backgroundColor: kRed,
          ),
        );
      }
    }
  }

  Future<void> _shareInvoice() async {
    try {
      final invoiceData = InvoiceData();
      invoiceData.invoiceNumber = _invoice!['invoice_number'] ?? '';
      invoiceData.issueDate = DateTime.parse(_invoice!['issue_date']);
      invoiceData.dueDate = _invoice!['due_date'] != null ? DateTime.parse(_invoice!['due_date']) : null;
      invoiceData.items = _items.map((item) => InvoiceItem(
        description: item['description'] ?? '',
        quantity: (item['quantity'] as num).toInt(),
        unitPrice: (item['unit_price'] as num).toDouble(),
      )).toList();
      invoiceData.applyTva = (_invoice!['tva_amount'] as num).toDouble() > 0;

      final pdfFile = await PdfService.generateInvoicePdf(
        invoiceData: invoiceData,
        companyName: _company!['name'] ?? '',
        companyPhone: _company!['mobile_money_number'] ?? '',
        companyEmail: _company!['email'] ?? '',
        companyAddress: _company!['address'] ?? '',
        companyIfu: _company!['ifu_nif'] ?? '',
        clientName: _client?['name'] ?? '',
        clientPhone: _client?['phone'] ?? '',
        clientEmail: _client?['email'] ?? '',
        clientAddress: _client?['address'] ?? '',
        logoUrl: _userProfile?['logo_url'],
        signatureUrl: _userProfile?['signature_url'],
        stampUrl: _userProfile?['stamp_url'],
      );

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Facture ${invoiceData.invoiceNumber}',
      );
    } catch (e) {
      print('❌ Erreur partage : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
            backgroundColor: kRed,
          ),
        );
      }
    }
  }

  Future<void> _markAsPaid() async {
    try {
      await DataService.updateInvoiceStatus(widget.invoiceId, 'paid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Facture marquée comme payée'),
            backgroundColor: kGreen,
          ),
        );
        _loadInvoiceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator(color: kDarkBlue)),
      );
    }

    if (_invoice == null || _company == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Facture introuvable',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final status = _invoice!['status'] ?? 'draft';
    final subtotal = (_invoice!['subtotal'] as num).toDouble();
    final tvaAmount = (_invoice!['tva_amount'] as num).toDouble();
    final totalAmount = (_invoice!['total_amount'] as num).toDouble();
    final isPaid = status == 'paid';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: kDarkBlue),
            onPressed: _downloadPDF,
            tooltip: 'Télécharger PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: kDarkBlue),
            onPressed: _shareInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kDarkBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  (_company!['name'] ?? 'E').toString().substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.novaFlat(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: kDarkBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _company!['name'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _company!['sector'] ?? 'Design - Développement - Conseil digital',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _company!['address'] ?? '',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                        Text(
                          'Tél: ${_company!['mobile_money_number'] ?? ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                        Text(
                          'IFU: ${_company!['ifu_nif'] ?? ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'FACTURE',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kDarkBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'N° ${_invoice!['invoice_number'] ?? ''}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: kGrayText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: kGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Payée',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kLightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(Icons.calendar_today_outlined, 'Date d\'émission', _formatDate(_invoice!['issue_date'])),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildInfoItem(Icons.event_outlined, 'Date d\'échéance', _formatDate(_invoice!['due_date'])),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildInfoItem(Icons.payment_outlined, 'Mode de paiement', _company!['mobile_money_operator'] ?? 'MTN Mobile Money'),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildInfoItem(Icons.business_outlined, 'IFU', _company!['ifu_nif'] ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ÉMETTEUR', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kGrayText, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Text(_company!['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text(_company!['address'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                        Text('Tél: ${_company!['mobile_money_number'] ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                        Text('IFU: ${_company!['ifu_nif'] ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FACTURÉ À', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kGrayText, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Text(_client?['name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text(_client?['address'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                        Text('Tél: ${_client?['phone'] ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                        Text(_client?['email'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: kDarkBlue,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('DESCRIPTION', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
                        Expanded(child: Text('QTÉ', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5), textAlign: TextAlign.center)),
                        Expanded(child: Text('PRIX UNITAIRE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5), textAlign: TextAlign.center)),
                        Expanded(child: Text('MONTANT HT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  ...List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isEven = index % 2 == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : kLightGray,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['description'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(item['description'] ?? '', style: GoogleFonts.inter(fontSize: 10, color: kGrayText)),
                              ],
                            ),
                          ),
                          Expanded(child: Text(item['quantity'].toString(), style: GoogleFonts.inter(fontSize: 12, color: Colors.black87), textAlign: TextAlign.center)),
                          Expanded(child: Text('${_formatAmount((item['unit_price'] as num).toDouble())}\nFCFA', style: GoogleFonts.inter(fontSize: 11, color: kGrayText), textAlign: TextAlign.center)),
                          Expanded(child: Text('${_formatAmount((item['total_price'] as num).toDouble())}\nFCFA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.right)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kLightGray, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONDITIONS DE PAIEMENT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kGrayText, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Text('Paiement dû dans les 30 jours suivant la date d\'émission. En cas de retard, pénalités de 1,5% par mois appliquées.', style: GoogleFonts.inter(fontSize: 10, color: kGrayText, height: 1.5)),
                        const SizedBox(height: 12),
                        Text('MODES DE PAIEMENT ACCEPTÉS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: kGrayText, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.phone_android, color: Colors.white, size: 12)),
                            const SizedBox(width: 8),
                            Text('MTN: ${_company!['mobile_money_number'] ?? ''}', style: GoogleFonts.inter(fontSize: 10, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 280,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _buildTotalRowWidget('Sous-total HT', '${_formatAmount(subtotal)} FCFA'),
                        const SizedBox(height: 8),
                        if (tvaAmount > 0) _buildTotalRowWidget('TVA (18%)', '${_formatAmount(tvaAmount)} FCFA'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: kDarkBlue, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL\nTTC', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                              Text('${_formatAmount(totalAmount)}\nFCFA', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!isPaid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markAsPaid,
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: Text('PAYÉE', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: kDarkBlue, size: 20),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: kGrayText), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildTotalRowWidget(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: kGrayText)),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}