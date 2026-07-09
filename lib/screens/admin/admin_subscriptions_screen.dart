import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  int _freeUsers = 0;
  int _starterUsers = 0;
  int _proUsers = 0;
  double _mrr = 0;
  bool _isLoading = true;
  String? _error;
  
  List<Map<String, dynamic>> _freeUsersList = [];
  List<Map<String, dynamic>> _starterUsersList = [];
  List<Map<String, dynamic>> _proUsersList = [];
  List<Map<String, dynamic>> _recentPayments = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // 1. Récupérer tous les profils
      final profilesRes = await client
          .from('profiles')
          .select('id, first_name, last_name, email, role, plan, created_at')
          .order('created_at', ascending: false);

      _freeUsers = 0;
      _starterUsers = 0;
      _proUsers = 0;
      _freeUsersList = [];
      _starterUsersList = [];
      _proUsersList = [];

      for (final profile in profilesRes) {
        final plan = profile['plan'] ?? 'free';
        final role = profile['role'] ?? 'user';
        final effectivePlan = role == 'admin' ? 'pro' : plan;

        switch (effectivePlan) {
          case 'pro':
            _proUsers++;
            _proUsersList.add(profile);
            break;
          case 'starter':
            _starterUsers++;
            _starterUsersList.add(profile);
            break;
          default:
            _freeUsers++;
            _freeUsersList.add(profile);
        }
      }

      _mrr = (_starterUsers * 3000) + (_proUsers * 7000);

      // 2. Récupérer les paiements réels
      final paymentsRes = await client
          .from('payments')
          .select('*, profiles(first_name, last_name, email)')
          .order('created_at', ascending: false)
          .limit(10);

      _recentPayments = List<Map<String, dynamic>>.from(paymentsRes);

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement abonnements : $e');
      if (!mounted) return;
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

  String _getUserName(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : (user['email'] ?? 'Utilisateur');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(child: CircularProgressIndicator(color: kDarkBlue)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Center(
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
        ),
      );
    }

    final totalUsers = _freeUsers + _starterUsers + _proUsers;
    final conversionRate = totalUsers > 0 ? ((_starterUsers + _proUsers) / totalUsers * 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDarkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abonnements & revenus', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('MRR · Churn · Conversions', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh, color: kDarkBlue),
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            Row(
              children: [
                _buildKpiCard('MRR', '${_formatAmount(_mrr)} FCFA / mois', 'Revenus mensuels', kGreen),
                const SizedBox(width: 16),
                _buildKpiCard('Taux conversion', '${conversionRate.toStringAsFixed(0)}%', 'Gratuit → payant', kDarkBlue),
                const SizedBox(width: 16),
                _buildKpiCard('Utilisateurs payants', '${_starterUsers + _proUsers}', 'Starter: $_starterUsers · Pro: $_proUsers', kOrange),
                const SizedBox(width: 16),
                _buildKpiCard('Total utilisateurs', '$totalUsers', 'Tous plans confondus', Colors.purple),
              ],
            ),
            const SizedBox(height: 24),

            // Plans Cards
            Row(
              children: [
                Expanded(
                  child: _buildPlanCard(
                    'Gratuit',
                    '0 FCFA / mois',
                    '$_freeUsers utilisateurs',
                    '3 factures/mois · 1 utilisateur · Support communautaire',
                    kGrayText,
                    onTap: () => _showUsersList('Utilisateurs Gratuits', _freeUsersList, kGrayText),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPlanCard(
                    'Starter',
                    '3 000 FCFA / mois',
                    '$_starterUsers utilisateurs',
                    'Factures illimitées · Export PDF pro · Assistant IA (100/mois)',
                    kOrange,
                    popular: true, // ✅ CORRECT : paramètre nommé
                    onTap: () => _showUsersList('Utilisateurs Starter', _starterUsersList, kOrange),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPlanCard(
                    'Pro',
                    '7 000 FCFA / mois',
                    '$_proUsers utilisateurs',
                    'Multi-utilisateurs · Relances auto · IA illimitée',
                    kDarkBlue,
                    onTap: () => _showUsersList('Utilisateurs Pro', _proUsersList, kDarkBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Paiements réels
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paiements récents (KKiaPay)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('${_recentPayments.length} transaction(s)', style: GoogleFonts.inter(fontSize: 12, color: kGrayText)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('Utilisateur', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                        Expanded(child: Text('Plan', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                        Expanded(child: Text('Montant', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                        Expanded(child: Text('Statut', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_recentPayments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.payment, size: 48, color: kGrayText),
                          const SizedBox(height: 12),
                          Text('Aucun paiement pour le moment', style: GoogleFonts.inter(fontSize: 14, color: kGrayText)),
                        ],
                      ),
                    )
                  else
                    ..._recentPayments.map((payment) {
                      final profiles = payment['profiles'] as Map<String, dynamic>?;
                      final userName = profiles != null
                          ? '${profiles['first_name'] ?? ''} ${profiles['last_name'] ?? ''}'.trim()
                          : 'Utilisateur';
                      final plan = payment['plan'] ?? 'starter';
                      final amount = payment['amount'] ?? 0;
                      final status = payment['status'] ?? 'pending';
                      
                      Color statusColor;
                      String statusText;
                      switch (status) {
                        case 'success':
                        case 'completed':
                          statusColor = kGreen;
                          statusText = 'OK';
                          break;
                        case 'failed':
                        case 'rejected':
                          statusColor = kRed;
                          statusText = 'Échec';
                          break;
                        default:
                          statusColor = kOrange;
                          statusText = 'En attente';
                      }

                      return Column(
                        children: [
                          _buildPaymentRow(
                            userName.isNotEmpty ? userName : 'Utilisateur',
                            plan.toUpperCase(),
                            '${_formatAmount(amount.toDouble())} F',
                            statusText,
                            statusColor,
                          ),
                          _buildDivider(),
                        ],
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ✅ CORRECT : Paramètres nommés {bool popular, VoidCallback? onTap}
  Widget _buildPlanCard(
    String name,
    String price,
    String users,
    String features,
    Color color, {
    bool popular = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: popular ? color : Colors.grey.shade200, width: popular ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                if (popular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('Populaire', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(price, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(users, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Text(features, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: color),
                const SizedBox(width: 4),
                Text('Voir la liste', style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                const Icon(Icons.arrow_forward, size: 12, color: kGrayText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String user, String plan, String amount, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(user, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87))),
          Expanded(child: Text(plan, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(child: Text(amount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade100, height: 1);
  }

  void _showUsersList(String title, List<Map<String, dynamic>> users, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('${users.length} utilisateur(s)', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 48, color: kGrayText),
                          const SizedBox(height: 12),
                          Text('Aucun utilisateur dans ce plan', style: GoogleFonts.inter(fontSize: 14, color: kGrayText)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final name = _getUserName(user);
                        final email = user['email'] ?? '';
                        final createdAt = user['created_at'] ?? '';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: color),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    Text(email, style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                                  ],
                                ),
                              ),
                              Text(_formatDate(createdAt), style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} sem.';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}