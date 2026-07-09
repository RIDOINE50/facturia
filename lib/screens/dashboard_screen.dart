import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'clients_screen.dart';
import 'create_invoice_step1.dart';
import 'assistant_screen.dart';
import 'invoices_screen.dart';
import 'services_screen.dart';
import 'settings_screen.dart';
import 'payment_screen.dart';
import 'admin/admin_dashboard_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _company;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        DataService.getUserProfile(user.id),
        DataService.getCompany(user.id),
        DataService.getDashboardStats(user.id),
        DataService.getRecentInvoices(user.id),
      ]);

      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _company = results[1] as Map<String, dynamic>?;
        _stats = results[2] as Map<String, dynamic>;
        _recentInvoices = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement dashboard : $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
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

  /// Détermine le plan actuel de l'utilisateur
  String _getCurrentPlan() {
    final role = _profile?['role'] ?? 'user';
    final plan = _profile?['plan'] ?? 'free';
    
    if (role == 'admin') return 'pro';
    if (plan == 'pro') return 'pro';
    if (plan == 'starter') return 'starter';
    return 'free';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(color: kDarkBlue),
        ),
      );
    }

    final firstName = _profile?['first_name'] ?? 'Utilisateur';
    final lastName = _profile?['last_name'] ?? '';
    final initials = '${firstName.isNotEmpty ? firstName[0] : 'U'}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

    final totalMonthAmount = (_stats?['totalMonthAmount'] ?? 0.0).toDouble();
    final paidAmount = (_stats?['paidAmount'] ?? 0.0).toDouble();
    final pendingAmount = (_stats?['pendingAmount'] ?? 0.0).toDouble();
    final totalInvoices = _stats?['totalInvoices'] ?? 0;
    final paidCount = _stats?['paidCount'] ?? 0;
    final pendingCount = _stats?['pendingCount'] ?? 0;
    final overdueCount = _stats?['overdueCount'] ?? 0;
    final totalClients = _stats?['totalClients'] ?? 0;

    final currentPlan = _getCurrentPlan();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour',
              style: GoogleFonts.inter(fontSize: 14, color: kGrayText),
            ),
            Text(
              '$firstName $lastName',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          // Badge du plan actuel
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: currentPlan == 'pro' ? kDarkBlue : (currentPlan == 'starter' ? kOrange : kGrayText),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentPlan.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Bouton Admin (visible seulement pour les admins)
          FutureBuilder<bool>(
            future: AuthService.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              
              final isAdmin = snapshot.data ?? false;
              if (!isAdmin) return const SizedBox.shrink();
              
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: kOrange, size: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
                  );
                },
                tooltip: 'Administration',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: kDarkBlue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kDarkBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: kDarkBlue,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD PRINCIPALE BLEUE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FACTURÉ CE MOIS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatAmount(totalMonthAmount)} FCFA',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatItem('PAYÉ', _formatAmount(paidAmount), kGreen),
                      const SizedBox(width: 16),
                      _buildStatItem('EN ATTENTE', _formatAmount(pendingAmount), kOrange),
                      const Spacer(),
                      Text(
                        'FACTURES\n$totalInvoices',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // STATS CARDS
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Payées',
                    '$paidCount',
                    '→ ce mois',
                    kGreen,
                    Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'En attente',
                    '$pendingCount',
                    'Relance due',
                    kOrange,
                    Icons.access_time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'En retard',
                    '$overdueCount',
                    '→ à relancer',
                    kRed,
                    Icons.warning_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Clients',
                    '$totalClients',
                    'actifs',
                    kDarkBlue,
                    Icons.people_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🎯 BANNIÈRE "PASSER AU PLAN PRO" (visible seulement si pas déjà Pro)
            if (currentPlan != 'pro')
              _buildUpgradeBanner(currentPlan),
            
            if (currentPlan != 'pro')
              const SizedBox(height: 20),

            // DERNIÈRES FACTURES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dernières factures',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InvoicesScreen()),
                    );
                  },
                  child: Text(
                    'Voir tout',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: kDarkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // LISTE FACTURES RÉELLES
            if (_recentInvoices.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.description_outlined, size: 48, color: kGrayText),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune facture pour le moment',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: kGrayText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cliquez sur + pour créer votre première facture',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: kGrayText,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._recentInvoices.map((invoice) {
                final clientName = invoice['clients']?['name'] ?? 'Client inconnu';
                final invoiceNumber = invoice['invoice_number'] ?? 'N/A';
                final amount = (invoice['total_amount'] ?? 0).toDouble();
                final status = invoice['status'] ?? 'draft';
                final initials = clientName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInvoiceCard(
                    clientName,
                    invoiceNumber,
                    '${_formatAmount(amount)} F',
                    _getStatusText(status),
                    _getStatusColor(status),
                    initials.isEmpty ? '?' : initials,
                    Colors.blue,
                  ),
                );
              }).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateInvoiceStep1()),
          );
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
        currentIndex: 0,
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

  /// 🎯 BANNIÈRE D'UPGRADE VERS LE PLAN PRO
  Widget _buildUpgradeBanner(String currentPlan) {
    final isStarter = currentPlan == 'starter';
    final title = isStarter ? 'Passez au plan Pro' : 'Passez au plan Starter';
    final subtitle = isStarter 
        ? 'Débloquez l\'IA illimitée, les relances auto et plus encore'
        : 'Factures illimitées, export PDF et assistant IA';
    final price = isStarter ? '7 000 FCFA/mois' : '3 000 FCFA/mois';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isStarter 
                ? [kDarkBlue, const Color(0xFF3B82F6)]
                : [kOrange, const Color(0xFFFBBF24)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isStarter ? kDarkBlue : kOrange).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'UPGRADE →',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isStarter ? kDarkBlue : kOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: kGrayText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(String client, String number, String amount, String status, Color statusColor, String initials, Color avatarColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: kGrayText,
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
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}