import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class AdminUserDetail extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminUserDetail({super.key, required this.user});

  @override
  State<AdminUserDetail> createState() => _AdminUserDetailState();
}

class _AdminUserDetailState extends State<AdminUserDetail> {
  Map<String, dynamic>? _company;
  int _invoiceCount = 0;
  int _clientCount = 0;
  double _revenue = 0;
  List<Map<String, dynamic>> _recentInvoices = [];
  List<Map<String, dynamic>> _activityHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = widget.user['id'];

      // 1. Récupérer les infos de l'entreprise
      final companyRes = await client
          .from('companies')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      _company = companyRes;

      // 2. Récupérer les factures
      final invoicesRes = await client
          .from('invoices')
          .select('*, clients(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _invoiceCount = invoicesRes.length;
      _revenue = invoicesRes.fold(0.0, (sum, inv) {
        return sum + ((inv['total_amount'] as num?)?.toDouble() ?? 0);
      });

      // 3. Récupérer les clients
      final clientsRes = await client
          .from('clients')
          .select('id')
          .eq('user_id', userId);
      _clientCount = clientsRes.length;

      // 4. Factures récentes (5 dernières)
      _recentInvoices = invoicesRes.take(5).map((inv) {
        final clientData = inv['clients'] as Map<String, dynamic>? ?? {};
        return {
          'number': inv['invoice_number'] ?? 'N/A',
          'client': clientData['name'] ?? 'Client inconnu',
          'amount': (inv['total_amount'] as num?)?.toDouble() ?? 0,
          'status': inv['status'] ?? 'draft',
          'date': inv['created_at'] != null ? DateTime.parse(inv['created_at']) : null,
        };
      }).toList();

      // 5. Construire l'historique d'activité
      _activityHistory = [];
      
      // Ajouter les factures récentes à l'historique
      for (final inv in _recentInvoices) {
        _activityHistory.add({
          'text': 'Facture ${inv['number']} générée · ${_formatAmount(inv['amount'])} FCFA',
          'date': inv['date'],
          'color': kDarkBlue,
        });
      }

      // Ajouter la date de création du compte
      final createdAt = widget.user['date'] != '-' ? widget.user['created_at'] : null;
      if (createdAt != null) {
        _activityHistory.add({
          'text': 'Compte créé',
          'date': DateTime.parse(createdAt),
          'color': kGrayText,
        });
      }

      // Trier par date (plus récent en premier)
      _activityHistory.sort((a, b) {
        final dateA = a['date'] as DateTime?;
        final dateB = b['date'] as DateTime?;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement détail utilisateur : $e');
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator(color: kDarkBlue)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: GoogleFonts.inter(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUserData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: kDarkBlue, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final roleColor = widget.user['role'] == 'admin' ? kOrange : kDarkBlue;
    final roleLabel = widget.user['role'] == 'admin' ? 'Admin' : 'Utilisateur';
    final createdAt = widget.user['created_at'] != null ? DateTime.parse(widget.user['created_at']) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user['name'], style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('Membre depuis ${_formatDate(createdAt)} · $roleLabel', style: GoogleFonts.inter(fontSize: 13, color: kGrayText)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Suspendre', style: GoogleFonts.inter(color: kOrange, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: kDarkBlue, foregroundColor: Colors.white),
            child: Text('Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(widget.user['initials'], style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.user['name'], style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text('${widget.user['email']} · ${widget.user['phone'] ?? 'Pas de téléphone'}', style: GoogleFonts.inter(fontSize: 13, color: kGrayText)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text('$roleLabel · Actif', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kGreen)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Infos
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 16),
                        _infoRow('Entreprise', _company?['name'] ?? widget.user['name']),
                        _infoRow('Ville', _company?['city'] ?? 'Non renseignée'),
                        _infoRow('Secteur', _company?['sector'] ?? 'Non renseigné'),
                        _infoRow('IFU/NIF', _company?['ifu_nif'] ?? 'Non renseigné'),
                        _infoRow('Mobile Money', _company?['mobile_money_operator'] != null 
                            ? '${_company!['mobile_money_operator']} · ${_company!['mobile_money_number'] ?? ''}'
                            : 'Non configuré'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Statistiques', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 16),
                        _statRow('Revenus générés', '${_formatAmount(_revenue)} FCFA'),
                        _statRow('Factures créées', '$_invoiceCount'),
                        _statRow('Clients enregistrés', '$_clientCount'),
                        _statRow('Messages IA utilisés', '84 / ∞'), // Simulé
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Historique
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Historique d\'activité', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 16),
                        if (_activityHistory.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text('Aucune activité récente', style: GoogleFonts.inter(color: kGrayText)),
                            ),
                          )
                        else
                          ..._activityHistory.take(10).map((item) => _historyItem(
                            item['text'],
                            _formatDateTime(item['date']),
                            item['color'],
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: kGrayText))),
          Expanded(flex: 3, child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: kGrayText)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _historyItem(String text, String date, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(date, style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}