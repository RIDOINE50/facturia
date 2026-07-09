import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_user_detail_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _selectedFilter = 'Tous';
  String _searchQuery = '';
  final List<String> _filters = ['Tous', 'Admin', 'Utilisateur'];

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _displayedUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      final profilesRes = await client
          .from('profiles')
          .select('id, first_name, last_name, email, role, created_at, phone')
          .order('created_at', ascending: false);

      final invoicesRes = await client
          .from('invoices')
          .select('user_id, total_amount, status');

      final Map<String, int> invoiceCount = {};
      final Map<String, double> userRevenue = {};

      for (final inv in invoicesRes) {
        final userId = inv['user_id'];
        final amount = (inv['total_amount'] as num?)?.toDouble() ?? 0;
        invoiceCount[userId] = (invoiceCount[userId] ?? 0) + 1;
        userRevenue[userId] = (userRevenue[userId] ?? 0) + amount;
      }

      _allUsers = profilesRes.map((p) {
        final userId = p['id'];
        final firstName = p['first_name'] ?? '';
        final lastName = p['last_name'] ?? '';
        final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
        final role = p['role'] ?? 'user';
        final createdAt = p['created_at'] != null ? DateTime.parse(p['created_at']) : null;

        return {
          'id': userId,
          'initials': initials.isNotEmpty ? initials : '?',
          'name': '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName' : 'Utilisateur',
          'email': p['email'] ?? '',
          'phone': p['phone'] ?? '',
          'role': role,
          'roleLabel': role == 'admin' ? 'Admin' : 'Utilisateur',
          'invoices': invoiceCount[userId] ?? 0,
          'revenue': userRevenue[userId] ?? 0.0,
          'date': createdAt != null ? _formatDate(createdAt) : '-',
          'created_at': p['created_at'],
          'status': 'Actif',
          'statusColor': kGreen,
        };
      }).toList();

      _applyFilters();
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement utilisateurs : $e');
      setState(() {
        _isLoading = false;
        _error = 'Erreur de chargement : $e';
      });
    }
  }

  void _applyFilters() {
    var filtered = _allUsers;

    if (_selectedFilter == 'Admin') {
      filtered = filtered.where((u) => u['role'] == 'admin').toList();
    } else if (_selectedFilter == 'Utilisateur') {
      filtered = filtered.where((u) => u['role'] == 'user').toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        final name = (u['name'] as String).toLowerCase();
        final email = (u['email'] as String).toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    _displayedUsers = filtered;
  }

  String _formatDate(DateTime date) {
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
              onPressed: _loadUsers,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gestion des utilisateurs', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('${_allUsers.length} comptes enregistrés', style: GoogleFonts.inter(fontSize: 14, color: kGrayText)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _loadUsers,
                    icon: const Icon(Icons.refresh, color: kDarkBlue),
                    tooltip: 'Actualiser',
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kDarkBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Exporter', style: GoogleFonts.inter(color: kDarkBlue, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _applyFilters();
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou email...',
                      prefixIcon: const Icon(Icons.search, color: kGrayText),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ..._filters.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChip(f, _selectedFilter == f),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _displayedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Aucun utilisateur trouvé', style: GoogleFonts.inter(fontSize: 14, color: kGrayText)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                        columns: const [
                          DataColumn(label: Text('Utilisateur')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Rôle')),
                          DataColumn(label: Text('Factures')),
                          DataColumn(label: Text('Revenus')),
                          DataColumn(label: Text('Inscription')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _displayedUsers.map((u) => _buildDataRow(u)).toList(),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Affichage 1–${_displayedUsers.length} sur ${_allUsers.length} utilisateurs', style: GoogleFonts.inter(fontSize: 13, color: kGrayText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool active) {
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
          color: active ? kDarkBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? kDarkBlue : Colors.grey.shade300),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: active ? Colors.white : kGrayText, fontWeight: FontWeight.w500)),
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> u) {
    final roleColor = u['role'] == 'admin' ? kOrange : kDarkBlue;
    return DataRow(
      cells: [
        DataCell(Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
            child: Center(child: Text(u['initials'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: roleColor))),
          ),
          const SizedBox(width: 12),
          Text(u['name'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ])),
        DataCell(Text(u['email'], style: GoogleFonts.inter(fontSize: 13, color: kDarkBlue))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(u['roleLabel'], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor)),
        )),
        DataCell(Text('${u['invoices']}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600))),
        DataCell(Text('${_formatAmount(u['revenue'])} F', style: GoogleFonts.inter(fontSize: 13, color: kGreen, fontWeight: FontWeight.w600))),
        DataCell(Text(u['date'], style: GoogleFonts.inter(fontSize: 13, color: kGrayText))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: u['statusColor'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(u['status'], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: u['statusColor'])),
        )),
        DataCell(IconButton(
          icon: const Icon(Icons.more_horiz, color: kGrayText, size: 20),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminUserDetail(user: u)),
          ),
        )),
      ],
    );
  }
}