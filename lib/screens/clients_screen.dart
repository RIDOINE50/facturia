import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_service.dart';
import 'dashboard_screen.dart';
import 'assistant_screen.dart';
import 'invoices_screen.dart';
import 'add_client_screen.dart';
import 'services_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Map<String, dynamic>> _clients = [];
  Map<String, Map<String, dynamic>> _clientStats = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Récupérer tous les clients
      final clients = await DataService.getAllClients(user.id);

      // 2. Calculer les stats pour chaque client
      final statsMap = <String, Map<String, dynamic>>{};
      for (var client in clients) {
        final clientId = client['id'] as String;
        final stats = await DataService.getClientStats(user.id, clientId);
        statsMap[clientId] = stats;
      }

      setState(() {
        _clients = clients;
        _clientStats = statsMap;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement clients : $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  double _getTotalFacture() {
    double total = 0;
    for (var stats in _clientStats.values) {
      total += (stats['totalAmount'] ?? 0).toDouble();
    }
    return total;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Payé':
        return kGreen;
      case 'En attente':
        return kOrange;
      case 'En retard':
        return kRed;
      case 'Nouveau':
        return kDarkBlue;
      default:
        return kGrayText;
    }
  }

  Color _getClientColor(String name) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).take(2).toList();
    if (parts.isEmpty) return '?';
    return parts.map((p) => p[0].toUpperCase()).join('');
  }

  List<Map<String, dynamic>> get _filteredClients {
    var filtered = _clients;

    // Filtre de recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        final name = (client['name'] ?? '').toString().toLowerCase();
        final phone = (client['phone'] ?? '').toString().toLowerCase();
        final email = (client['email'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || phone.contains(query) || email.contains(query);
      }).toList();
    }

    // Filtre par statut
    if (_selectedFilter != 'Tous') {
      filtered = filtered.where((client) {
        final clientId = client['id'] as String;
        final stats = _clientStats[clientId];
        final status = stats?['lastStatus'] ?? 'Nouveau';
        return status == _selectedFilter;
      }).toList();
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
              'Mes clients',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_clients.length} client${_clients.length > 1 ? 's' : ''} · ${_formatAmount(_getTotalFacture())} FCFA facturés',
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un client...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                      prefixIcon: const Icon(Icons.search, color: kGrayText),
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
                        _buildFilterChip('Tous', true),
                        const SizedBox(width: 8),
                        _buildFilterChip('Payé', false),
                        const SizedBox(width: 8),
                        _buildFilterChip('En attente', false),
                        const SizedBox(width: 8),
                        _buildFilterChip('En retard', false),
                        const SizedBox(width: 8),
                        _buildFilterChip('Nouveau', false),
                      ],
                    ),
                  ),
                ),

                // Liste des clients
                Expanded(
                  child: _filteredClients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, size: 64, color: kGrayText),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _selectedFilter != 'Tous'
                                    ? 'Aucun client trouvé'
                                    : 'Aucun client pour le moment',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: kGrayText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _selectedFilter != 'Tous'
                                    ? 'Essayez de modifier vos filtres'
                                    : 'Ajoutez votre premier client avec le bouton +',
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
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            final clientId = client['id'] as String;
                            final stats = _clientStats[clientId] ?? {};
                            final totalAmount = (stats['totalAmount'] ?? 0.0).toDouble();
                            final invoiceCount = stats['invoiceCount'] ?? 0;
                            final status = stats['lastStatus'] ?? 'Nouveau';
                            final name = client['name'] ?? 'Client inconnu';
                            final phone = client['phone'] ?? '';
                            final color = _getClientColor(name);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildClientCard(
                                name,
                                phone,
                                _formatAmount(totalAmount),
                                invoiceCount > 0 ? '$invoiceCount facture${invoiceCount > 1 ? 's' : ''}' : '',
                                _getInitials(name),
                                color,
                                status,
                                _getStatusColor(status),
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
      MaterialPageRoute(builder: (context) => const AddClientScreen()),
    );
    // Recharger les clients si on revient de l'écran d'ajout
    if (result == true || result == null) {
      _loadClients();
    }
  },
  backgroundColor: kDarkBlue,
  child: const Icon(Icons.person_add, size: 24),
),
      bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  backgroundColor: Colors.white,
  selectedItemColor: kDarkBlue,
  unselectedItemColor: kGrayText,
  selectedFontSize: 11,
  unselectedFontSize: 11,
  currentIndex: 1, // ← Change selon l'écran (voir ci-dessous)
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
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Services'), // ← NOUVEAU
  ],
),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    final selected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kDarkBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kDarkBlue : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : kGrayText,
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(
    String name,
    String phone,
    String amount,
    String invoices,
    String initials,
    Color color,
    String status,
    Color statusColor,
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
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
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone.isNotEmpty ? phone : 'Pas de téléphone',
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
                '$amount F',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              if (invoices.isNotEmpty)
                Text(
                  invoices,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: kGrayText,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: kGrayText),
        ],
      ),
    );
  }
}