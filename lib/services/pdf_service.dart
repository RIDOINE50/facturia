import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/invoice_data.dart';

class PdfService {
  static Future<File> generateInvoicePdf({
    required InvoiceData invoiceData,
    required String companyName,
    required String companyPhone,
    required String companyEmail,
    required String companyAddress,
    required String companyIfu,
    required String clientName,
    required String clientPhone,
    required String clientEmail,
    required String clientAddress,
    String? logoUrl,
    String? signatureUrl,
    String? stampUrl,
  }) async {
    print('🔍 [PDF] Début génération PDF');
    print('🔍 [PDF] Logo URL : $logoUrl');
    print('🔍 [PDF] Signature URL : $signatureUrl');
    print('🔍 [PDF] Stamp URL : $stampUrl');

    final pdf = pw.Document();

    print('🔍 [PDF] Téléchargement des images...');
    final logoBytes = logoUrl != null ? await _downloadImageBytes(logoUrl) : null;
    final signatureBytes = signatureUrl != null ? await _downloadImageBytes(signatureUrl) : null;
    final stampBytes = stampUrl != null ? await _downloadImageBytes(stampUrl) : null;

    print('✅ [PDF] Logo : ${logoBytes != null ? "OK" : "NULL"}');
    print('✅ [PDF] Signature : ${signatureBytes != null ? "OK" : "NULL"}');
    print('✅ [PDF] Cachet : ${stampBytes != null ? "OK" : "NULL"}');

    final kDarkBlue = PdfColor.fromInt(0xFF1E3A8A);
    final kGray = PdfColor.fromInt(0xFF6B7280);
    final kLightGray = PdfColor.fromInt(0xFFF3F4F6);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER AVEC LOGO
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoBytes != null) ...[
                          pw.Container(
                            width: 80,
                            height: 80,
                            decoration: pw.BoxDecoration(
                              image: pw.DecorationImage(
                                image: pw.MemoryImage(logoBytes),
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                        ],
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                companyName,
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: kDarkBlue,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              if (companyIfu.isNotEmpty)
                                pw.Text(
                                  'IFU: $companyIfu',
                                  style: pw.TextStyle(fontSize: 10, color: kGray),
                                ),
                              pw.SizedBox(height: 8),
                              pw.Text(companyAddress, style: pw.TextStyle(fontSize: 10, color: kGray)),
                              pw.Text('Tel: $companyPhone', style: pw.TextStyle(fontSize: 10, color: kGray)),
                              if (companyEmail.isNotEmpty)
                                pw.Text(companyEmail, style: pw.TextStyle(fontSize: 10, color: kGray)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    color: kDarkBlue,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'FACTURE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoiceData.invoiceNumber,
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // INFOS FACTURE
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: kLightGray,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date emission', style: pw.TextStyle(fontSize: 10, color: kGray)),
                        pw.Text(_formatDate(invoiceData.issueDate), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    if (invoiceData.dueDate != null)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Date echeance', style: pw.TextStyle(fontSize: 10, color: kGray)),
                          pw.Text(_formatDate(invoiceData.dueDate!), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Mode de paiement', style: pw.TextStyle(fontSize: 10, color: kGray)),
                        pw.Text('Mobile Money', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // CLIENT
              pw.Text(
                'FACTURE A',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kGray),
              ),
              pw.SizedBox(height: 8),
              pw.Text(clientName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              if (clientAddress.isNotEmpty) pw.Text(clientAddress, style: pw.TextStyle(fontSize: 10, color: kGray)),
              if (clientPhone.isNotEmpty) pw.Text('Tel: $clientPhone', style: pw.TextStyle(fontSize: 10, color: kGray)),
              if (clientEmail.isNotEmpty) pw.Text(clientEmail, style: pw.TextStyle(fontSize: 10, color: kGray)),

              pw.SizedBox(height: 30),

              // TABLEAU
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: kDarkBlue),
                cellStyle: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                cellAlignment: pw.Alignment.centerLeft,
                headerPadding: const pw.EdgeInsets.all(8),
                cellPadding: const pw.EdgeInsets.all(8),
                headerHeight: 30,
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                headers: ['DESCRIPTION', 'QTE', 'PRIX UNIT.', 'MONTANT HT'],
                data: invoiceData.items.map((item) {
                  return [
                    item.description,
                    item.quantity.toString(),
                    '${_formatAmount(item.unitPrice)} FCFA',
                    '${_formatAmount(item.totalPrice)} FCFA',
                  ];
                }).toList(),
              ),

              pw.Spacer(),

              // TOTAUX
              pw.Row(
                children: [
                  pw.Expanded(child: pw.SizedBox()),
                  pw.SizedBox(
                    width: 250,
                    child: pw.Column(
                      children: [
                        _buildTotalRow('Sous-total HT', _formatAmount(invoiceData.subtotal), kGray),
                        if (invoiceData.applyTva)
                          _buildTotalRow('TVA (18%)', _formatAmount(invoiceData.tvaAmount), kGray),
                        pw.SizedBox(height: 8),
                        pw.Divider(color: kGray, thickness: 1),
                        pw.SizedBox(height: 8),
                        _buildTotalRow(
                          'TOTAL TTC',
                          _formatAmount(invoiceData.totalAmount),
                          kDarkBlue,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // CONDITIONS
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: kLightGray,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CONDITIONS DE PAIEMENT',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kGray),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Paiement du dans les 30 jours. En cas de retard, penalites de 1,5% par mois appliquees.',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'MODES DE PAIEMENT ACCEPTES',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: kGray),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'MTN Mobile Money : $companyPhone',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                    ),
                  ],
                ),
              ),

              // SIGNATURE ET CACHET
              if (signatureBytes != null || stampBytes != null) ...[
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (stampBytes != null)
                      pw.Container(
                        width: 100,
                        height: 100,
                        margin: const pw.EdgeInsets.only(right: 20),
                        child: pw.Column(
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                decoration: pw.BoxDecoration(
                                  image: pw.DecorationImage(
                                    image: pw.MemoryImage(stampBytes),
                                    fit: pw.BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Cachet',
                              style: pw.TextStyle(fontSize: 9, color: kGray, fontStyle: pw.FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    if (signatureBytes != null)
                      pw.Container(
                        width: 150,
                        height: 100,
                        child: pw.Column(
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                decoration: pw.BoxDecoration(
                                  image: pw.DecorationImage(
                                    image: pw.MemoryImage(signatureBytes),
                                    fit: pw.BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              width: double.infinity,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(top: pw.BorderSide(color: kGray, width: 0.5)),
                              ),
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                'Signature',
                                style: pw.TextStyle(fontSize: 9, color: kGray, fontStyle: pw.FontStyle.italic),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );

    // Sauvegarder dans Downloads
    final directory = await getExternalStorageDirectory();
    final downloadsDir = Directory('${directory!.path}/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    final fileName = '${invoiceData.invoiceNumber}.pdf';
    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    print('✅ [PDF] Fichier sauvegardé : ${file.path}');

    return file;
  }

  // NOUVELLE FONCTION : Télécharger les bytes directement
  static Future<Uint8List?> _downloadImageBytes(String url) async {
    print('🔍 [DOWNLOAD] URL : $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('📡 [DOWNLOAD] Réponse HTTP : ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ [DOWNLOAD] Image téléchargée : ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('❌ [DOWNLOAD] Erreur HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [DOWNLOAD] Erreur : $e');
      return null;
    }
  }

  static pw.Widget _buildTotalRow(String label, String value, PdfColor color, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 11,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            '$value FCFA',
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 11,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}