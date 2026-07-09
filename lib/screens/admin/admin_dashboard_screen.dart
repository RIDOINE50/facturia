import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _totalInvoices = 0;
  int _totalClients = 0;
  double _totalRevenue = 0;
  double _paidRevenue = 0;
  double _pendingRevenue = 0;
  int _paidCount = 0;
  int _pendingCount = 0;
  int _overdueCount = 0;
  int _draftCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // 1. Nombre total d'utilisateurs
      final usersRes = await client.from('profiles').select('id, role');
      _totalUsers = usersRes.length;

      // 2. Nombre total de clients
      final clientsRes = await client.from('clients').select('id');
      _totalClients = clientsRes.length;

      // 3. Factures (toutes)
      final invoicesRes = await client
          .from('invoices')
          .select('total_amount, status');
      
      _totalInvoices = invoicesRes.length;
      
      // Calcul des revenus et statuts
      _totalRevenue = 0;
      _paidRevenue = 0;
      _pendingRevenue = 0;
      _paidCount = 0;
      _pendingCount = 0;
      _overdueCount = 0;
      _draftCount = 0;

      for (final inv in invoicesRes) {
        final amount = (inv['total_amount'] as num?)?.toDouble() ?? 0;
        final status = inv['status'] ?? 'draft';
        
        _totalRevenue += amount;
        
        if (status == 'paid') {
          _paidRevenue += amount;
          _paidCount++;
        } else if (status == 'sent') {
          _pendingRevenue += amount;
          _pendingCount++;
        } else if (status == 'overdue') {
          _overdueCount++;
        } else if (status == 'draft') {
          _draftCount++;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement stats admin : $e');
      setState(() {
        _isLoading = false;
        _error = 'Erreur de chargement : $e';
      });
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
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
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: kDarkBlue, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de bord',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vue d\'ensemble de la plateforme FactuRIA',
                      style: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh, color: kDarkBlue),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ligne 1 : Les 4 cartes KPI (VRAIES DONNÉES)
            Row(
              children: [
                _buildKpiCard(
                  'Revenus totaux',
                  '${_formatAmount(_totalRevenue)} FCFA',
                  'Toutes factures',
                  kGreen,
                  Icons.attach_money,
                ),
                const SizedBox(width: 20),
                _buildKpiCard(
                  'Utilisateurs',
                  '$_totalUsers',
                  'Comptes enregistrés',
                  kDarkBlue,
                  Icons.people,
                ),
                const SizedBox(width: 20),
                _buildKpiCard(
                  'Factures créées',
                  '$_totalInvoices',
                  'Total global',
                  kOrange,
                  Icons.description,
                ),
                const SizedBox(width: 20),
                _buildKpiCard(
                  'Clients',
                  '$_totalClients',
                  'Tous utilisateurs',
                  Colors.purple,
                  Icons.business,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ligne 2 : Statuts des factures
            Row(
              children: [
                _buildKpiCard(
                  'Payées',
                  '$_paidCount',
                  '${_formatAmount(_paidRevenue)} F',
                  kGreen,
                  Icons.check_circle,
                ),
                const SizedBox(width: 20),
                _buildKpiCard(
                  'En attente',
                  '$_pendingCount',
                  '${_formatAmount(_pendingRevenue)} F',
                  kOrange,
                  Icons.access_time,
                ),
                const SizedBox(width: 20),
                _buildKpiCard(
                  'En retard',
                  '$_overdueCount',
                  'À relancer',
                  const Color(0xFFEF4444),
                  Icons.warning,
                ),
                const SizedBox(width: 20),
                _buildKpiCard(
                  'Brouillons',
                  '$_draftCount',
                  'Non envoyées',
                  kGrayText,
                  Icons.drafts,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ligne 3 : Répartition visuelle
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildSectionCard(
                    'Répartition des factures',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressBar('Payées', _paidCount, _totalInvoices, kGreen),
                        const SizedBox(height: 16),
                        _buildProgressBar('En attente', _pendingCount, _totalInvoices, kOrange),
                        const SizedBox(height: 16),
                        _buildProgressBar('En retard', _overdueCount, _totalInvoices, const Color(0xFFEF4444)),
                        const SizedBox(height: 16),
                        _buildProgressBar('Brouillons', _draftCount, _totalInvoices, kGrayText),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildSectionCard(
                    'Résumé financier',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow('Total facturé', '${_formatAmount(_totalRevenue)} F', kDarkBlue),
                        const SizedBox(height: 16),
                        _buildStatRow('Encaissé', '${_formatAmount(_paidRevenue)} F', kGreen),
                        const SizedBox(height: 16),
                        _buildStatRow('À encaisser', '${_formatAmount(_pendingRevenue)} F', kOrange),
                        const SizedBox(height: 16),
                        _buildStatRow('Moy. facture', _totalInvoices > 0 ? '${_formatAmount(_totalRevenue / _totalInvoices)} F' : '0 F', Colors.purple),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600))),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final percent = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
            Text('$count (${(percent * 100).toStringAsFixed(0)}%)', style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87))),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}