import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class AdminInvoicesScreen extends StatefulWidget {
  const AdminInvoicesScreen({super.key});

  @override
  State<AdminInvoicesScreen> createState() => _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends State<AdminInvoicesScreen> {
  String _selectedFilter = 'Toutes';
  String _searchQuery = '';
  final List<String> _filters = ['Toutes', 'Payées', 'En attente', 'En retard', 'Brouillons'];

  List<Map<String, dynamic>> _allInvoices = [];
  List<Map<String, dynamic>> _displayedInvoices = [];
  int _paidCount = 0;
  int _pendingCount = 0;
  int _overdueCount = 0;
  int _draftCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // 1. Récupérer toutes les factures avec les infos utilisateur et client
      final invoicesRes = await client
          .from('invoices')
          .select('*, profiles(first_name, last_name, email), clients(name)')
          .order('created_at', ascending: false);

      // 2. Construire la liste complète
      _allInvoices = invoicesRes.map((inv) {
        final profile = inv['profiles'] as Map<String, dynamic>? ?? {};
        final clientData = inv['clients'] as Map<String, dynamic>? ?? {};
        final status = inv['status'] ?? 'draft';
        final amount = (inv['total_amount'] as num?)?.toDouble() ?? 0;
        final createdAt = inv['created_at'] != null ? DateTime.parse(inv['created_at']) : null;

        return {
          'id': inv['id'],
          'number': inv['invoice_number'] ?? 'N/A',
          'user_name': '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
          'user_email': profile['email'] ?? '',
          'client_name': clientData['name'] ?? 'Client inconnu',
          'amount': amount,
          'status': status,
          'date': createdAt != null ? _formatDate(createdAt) : '-',
        };
      }).toList();

      // 3. Compter les statuts
      _paidCount = _allInvoices.where((i) => i['status'] == 'paid').length;
      _pendingCount = _allInvoices.where((i) => i['status'] == 'sent').length;
      _overdueCount = _allInvoices.where((i) => i['status'] == 'overdue').length;
      _draftCount = _allInvoices.where((i) => i['status'] == 'draft').length;

      _applyFilters();
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement factures : $e');
      setState(() {
        _isLoading = false;
        _error = 'Erreur de chargement : $e';
      });
    }
  }

  void _applyFilters() {
    var filtered = _allInvoices;

    // Filtre par statut
    if (_selectedFilter == 'Payées') {
      filtered = filtered.where((i) => i['status'] == 'paid').toList();
    } else if (_selectedFilter == 'En attente') {
      filtered = filtered.where((i) => i['status'] == 'sent').toList();
    } else if (_selectedFilter == 'En retard') {
      filtered = filtered.where((i) => i['status'] == 'overdue').toList();
    } else if (_selectedFilter == 'Brouillons') {
      filtered = filtered.where((i) => i['status'] == 'draft').toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((i) {
        final number = (i['number'] as String).toLowerCase();
        final userName = (i['user_name'] as String).toLowerCase();
        final clientName = (i['client_name'] as String).toLowerCase();
        return number.contains(query) || userName.contains(query) || clientName.contains(query);
      }).toList();
    }

    _displayedInvoices = filtered;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return kGreen;
      case 'sent':
        return kOrange;
      case 'overdue':
        return kRed;
      default:
        return kGrayText;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Payée';
      case 'sent':
        return 'Attente';
      case 'overdue':
        return 'En retard';
      default:
        return 'Brouillon';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kDarkBlue));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.inter(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadInvoices,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: kDarkBlue, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toutes les factures', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('${_allInvoices.length} factures créées sur la plateforme', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadInvoices,
            icon: const Icon(Icons.refresh, color: kDarkBlue),
            tooltip: 'Actualiser',
          ),
          TextButton.icon(
            icon: const Icon(Icons.download, color: kDarkBlue),
            label: Text('Exporter CSV', style: GoogleFonts.inter(color: kDarkBlue, fontWeight: FontWeight.w600)),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats rapides (VRAIES DONNÉES)
            Row(
              children: [
                _buildQuickStat('Payées', '$_paidCount', kGreen),
                const SizedBox(width: 12),
                _buildQuickStat('En attente', '$_pendingCount', kOrange),
                const SizedBox(width: 12),
                _buildQuickStat('En retard', '$_overdueCount', kRed),
                const SizedBox(width: 12),
                _buildQuickStat('Brouillons', '$_draftCount', kGrayText),
              ],
            ),
            const SizedBox(height: 20),

            // Recherche et filtres
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _applyFilters();
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher par n°, client ou utilisateur...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ..._filters.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(f, _selectedFilter == f),
                )),
              ],
            ),
            const SizedBox(height: 20),

            // Tableau
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: _displayedInvoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Aucune facture trouvée', style: GoogleFonts.inter(fontSize: 14, color: kGrayText)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text('N°', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                                Expanded(flex: 2, child: Text('Utilisateur', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                                Expanded(flex: 2, child: Text('Client facturé', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                                Expanded(child: Text('Montant TTC', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                                Expanded(child: Text('Date', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                                Expanded(child: Text('Statut', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                                const SizedBox(width: 40),
                              ],
                            ),
                          ),
                          // Liste
                          Expanded(
                            child: ListView.separated(
                              itemCount: _displayedInvoices.length,
                              separatorBuilder: (context, index) => _buildDivider(),
                              itemBuilder: (context, index) {
                                final inv = _displayedInvoices[index];
                                return _buildInvoiceRow(
                                  inv['number'],
                                  inv['user_name'],
                                  inv['client_name'],
                                  '${_formatAmount(inv['amount'])} F',
                                  inv['date'],
                                  _getStatusText(inv['status']),
                                  _getStatusColor(inv['status']),
                                );
                              },
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

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kDarkBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? kDarkBlue : Colors.grey.shade300),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildInvoiceRow(String number, String user, String client, String amount, String date, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(number, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: kDarkBlue))),
          Expanded(flex: 2, child: Text(user, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87))),
          Expanded(flex: 2, child: Text(client, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(child: Text(amount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold))),
          Expanded(child: Text(date, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade100, height: 1);
  }
}