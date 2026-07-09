import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_service.dart';
import 'dashboard_screen.dart';
import 'clients_screen.dart';
import 'assistant_screen.dart';
import 'create_invoice_step1.dart';
import 'services_screen.dart'; 
import 'invoice_detail_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final invoices = await DataService.getAllInvoices(user.id);
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement factures : $e');
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // MENU D'ACTION SUR UNE FACTURE
  // ==========================================
    void _showInvoiceActions(BuildContext context, String invoiceId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Actions sur la facture',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Statut actuel : $currentStatus',
                style: GoogleFonts.inter(fontSize: 14, color: kGrayText),
              ),
              const SizedBox(height: 24),
              
              // ==========================================
              // CAS 1 : FACTURE DÉJÀ PAYÉE → AUCUNE ACTION
              // ==========================================
              if (currentStatus == 'Payée')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: kGreen, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Facture payée',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cette facture est clôturée.\nAucune modification possible.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kGrayText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

              // ==========================================
              // CAS 2 : BROUILLON → seulement "Envoyée"
              // ==========================================
              if (currentStatus == 'Brouillon') ...[
                _buildActionOption(
                  context, invoiceId, 'sent',
                  icon: Icons.send_outlined,
                  title: 'Marquer comme envoyée',
                  subtitle: 'Finaliser et envoyer au client',
                  color: kOrange,
                ),
                const SizedBox(height: 12),
                _buildInfoBox(
                  '💡 Un brouillon ne peut être que finalisé.\nVous ne pouvez pas le marquer payé directement.',
                  Colors.blue,
                ),
              ],

              // ==========================================
              // CAS 3 : ENVOYÉE → Payée, En retard, ou Brouillon
              // ==========================================
              if (currentStatus == 'En attente') ...[
                _buildActionOption(
                  context, invoiceId, 'paid',
                  icon: Icons.check_circle_outline,
                  title: '✅ Marquer comme payée',
                  subtitle: 'Le client a réglé la facture',
                  color: kGreen,
                ),
                const SizedBox(height: 12),
                _buildActionOption(
                  context, invoiceId, 'overdue',
                  icon: Icons.warning_amber_outlined,
                  title: '⚠️ Marquer comme en retard',
                  subtitle: 'Le délai de paiement est dépassé',
                  color: kRed,
                ),
                const SizedBox(height: 12),
                _buildActionOption(
                  context, invoiceId, 'draft',
                  icon: Icons.drafts_outlined,
                  title: 'Remettre en brouillon',
                  subtitle: 'Annuler l\'envoi',
                  color: kGrayText,
                ),
              ],

              // ==========================================
              // CAS 4 : EN RETARD → Payée ou Envoyée (pas Brouillon !)
              // ==========================================
              if (currentStatus == 'En retard') ...[
                _buildActionOption(
                  context, invoiceId, 'paid',
                  icon: Icons.check_circle_outline,
                  title: '✅ Marquer comme payée',
                  subtitle: 'Le client a enfin réglé',
                  color: kGreen,
                ),
                const SizedBox(height: 12),
                _buildActionOption(
                  context, invoiceId, 'sent',
                  icon: Icons.send_outlined,
                  title: 'Remettre comme envoyée',
                  subtitle: 'Corriger la date d\'échéance',
                  color: kOrange,
                ),
                const SizedBox(height: 12),
                _buildInfoBox(
                  '💡 Une facture en retard ne peut pas redevenir brouillon.\nElle a déjà été envoyée au client.',
                  Colors.orange,
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBox(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: color,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildActionOption(BuildContext context, String invoiceId, String newStatus, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () async {
        try {
          await DataService.updateInvoiceStatus(invoiceId, newStatus);
          if (context.mounted) {
            Navigator.pop(context);
            _loadInvoices();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Statut mis à jour : ${_getStatusText(newStatus)}'),
                backgroundColor: color,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: kGrayText)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kGrayText),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // UTILITAIRES
  // ==========================================
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
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Payée';
      case 'sent':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      case 'draft':
        return 'Brouillon';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return kGreen;
      case 'sent':
        return kOrange;
      case 'overdue':
        return kRed;
      case 'draft':
        return kGrayText;
      default:
        return kGrayText;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'sent':
        return Icons.access_time;
      case 'overdue':
        return Icons.warning_amber;
      case 'draft':
        return Icons.drafts;
      default:
        return Icons.description;
    }
  }

  double _getTotalAmount() {
    return _invoices.fold(0.0, (sum, invoice) {
      return sum + ((invoice['total_amount'] ?? 0).toDouble());
    });
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    var filtered = _invoices;

    // 🔍 RECHERCHE INTELLIGENTE
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      
      filtered = filtered.where((invoice) {
        // Recherche par numéro de facture
        final number = (invoice['invoice_number'] ?? '').toString().toLowerCase();
        if (number.contains(query)) return true;
        
        // Recherche par nom du client
        final clientName = (invoice['clients']?['name'] ?? '').toString().toLowerCase();
        if (clientName.contains(query)) return true;
        
        // Recherche par montant (ex: "150000" ou "150 000")
        final amount = (invoice['total_amount'] ?? 0).toDouble();
        final amountStr = amount.toStringAsFixed(0);
        final amountFormatted = amountStr.replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
        if (amountStr.contains(query) || amountFormatted.contains(query)) return true;
        
        // Recherche par date (ex: "20/08" ou "2026" ou "20/08/2026")
        final issueDate = invoice['issue_date'] as String?;
        if (issueDate != null) {
          final formattedDate = _formatDate(issueDate);
          if (formattedDate.contains(query)) return true;
          if (issueDate.contains(query)) return true;
        }
        
        // Recherche par statut (ex: "payée", "retard", "brouillon")
        final status = _getStatusText(invoice['status'] ?? 'draft').toLowerCase();
        if (status.contains(query)) return true;
        
        return false;
      }).toList();
    }

    // Filtre par statut
    if (_selectedFilter != 'Toutes') {
      final statusMap = {
        'Payées': 'paid',
        'En attente': 'sent',
        'En retard': 'overdue',
        'Brouillons': 'draft',
      };
      final targetStatus = statusMap[_selectedFilter];
      if (targetStatus != null) {
        filtered = filtered.where((invoice) => invoice['status'] == targetStatus).toList();
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes factures',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_invoices.length} facture${_invoices.length > 1 ? 's' : ''} · ${_formatAmount(_getTotalAmount())} FCFA',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: kGrayText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: kDarkBlue),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kDarkBlue),
            )
          : Column(
              children: [
                // Barre de recherche
                                // Barre de recherche intelligente
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher (client, n°, montant, date...)',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                      prefixIcon: const Icon(Icons.search, color: kGrayText),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: kGrayText),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kDarkBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),

                // Filtres rapides
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Toutes'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Payées'),
                        const SizedBox(width: 8),
                        _buildFilterChip('En attente'),
                        const SizedBox(width: 8),
                        _buildFilterChip('En retard'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Brouillons'),
                      ],
                    ),
                  ),
                ),

                // Liste des factures
                Expanded(
                  child: _filteredInvoices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.description_outlined, size: 64, color: kGrayText),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _selectedFilter != 'Toutes'
                                    ? 'Aucune facture trouvée'
                                    : 'Aucune facture pour le moment',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: kGrayText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _selectedFilter != 'Toutes'
                                    ? 'Essayez de modifier vos filtres'
                                    : 'Créez votre première facture avec le bouton +',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: kGrayText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            final invoiceId = invoice['id'] as String;
                            final clientName = invoice['clients']?['name'] ?? 'Client inconnu';
                            final invoiceNumber = invoice['invoice_number'] ?? 'N/A';
                            final date = _formatDate(invoice['issue_date']);
                            final amount = (invoice['total_amount'] ?? 0).toDouble();
                            final status = invoice['status'] ?? 'draft';
                            
                            // Calcul automatique "En retard"
                            String displayStatus = _getStatusText(status);
                            Color displayColor = _getStatusColor(status);
                            IconData displayIcon = _getStatusIcon(status);
                            
                            final dueDateStr = invoice['due_date'] as String?;
                            if (dueDateStr != null && status != 'paid' && status != 'cancelled') {
                              final dueDate = DateTime.tryParse(dueDateStr);
                              if (dueDate != null && dueDate.isBefore(DateTime.now())) {
                                displayStatus = 'En retard';
                                displayColor = kRed;
                                displayIcon = Icons.warning_amber;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InvoiceDetailScreen(invoiceId: invoiceId),
    ),
  );
},                                child: _buildInvoiceCard(
                                  invoiceNumber,
                                  clientName,
                                  date,
                                  '${_formatAmount(amount)} F',
                                  displayStatus,
                                  displayColor,
                                  displayIcon,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateInvoiceStep1()),
          );
          if (result == true || result == null) {
            _loadInvoices();
          }
        },
        backgroundColor: kDarkBlue,
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: kDarkBlue,
        unselectedItemColor: kGrayText,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InvoicesScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AssistantScreen()));
          } else if (index == 4) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServicesScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Factures'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'Assistant'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Services'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kDarkBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kDarkBlue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : kGrayText,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    String number,
    String client,
    String date,
    String amount,
    String status,
    Color statusColor,
    IconData statusIcon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  client,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: kGrayText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: kGrayText, size: 18),
        ],
      ),
    );
  }
}