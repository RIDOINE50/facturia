import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_service.dart';
import 'edit_profile_screen.dart';
import 'subscription_screen.dart';
import 'dashboard_screen.dart';
import 'clients_screen.dart';
import 'assistant_screen.dart';
import 'invoices_screen.dart';
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightBlue = Color(0xFFF0F9FF);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _company;
  String? _userEmail;
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
      final profile = await DataService.getUserProfile(user.id);
      final company = await DataService.getCompany(user.id);

      setState(() {
        _profile = profile;
        _company = company;
        _userEmail = user.email;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement profil : $e');
      setState(() => _isLoading = false);
    }
  }

  String _getInitials() {
    final firstName = _profile?['first_name'] ?? '';
    final lastName = _profile?['last_name'] ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return 'KM';
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  String _getFullName() {
    final firstName = _profile?['first_name'] ?? '';
    final lastName = _profile?['last_name'] ?? '';
    return '$firstName $lastName'.trim().isEmpty ? 'Kofi Mensah' : '$firstName $lastName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mon profil',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              ).then((_) => _loadData());
            },
            child: Text(
              'Modifier',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: kDarkBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kDarkBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // HEADER PROFIL
                  // ==========================================
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
                      children: [
                        // Avatar + Nom
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(),
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
                                    _getFullName(),
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _userEmail ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kOrange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Plan Pro · Actif',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('18', 'Factures'),
                            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                            _buildStatItem('7', 'Clients'),
                            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                            _buildStatItem('840K', 'FCFA facturé'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // INFORMATIONS PERSONNELLES
                  // ==========================================
                  _buildSectionTitle('INFORMATIONS PERSONNELLES'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.business, 'Nom de l\'entreprise', _company?['name'] ?? 'Kofi Design Studio'),
                    _buildDivider(),
                    _buildInfoRow(Icons.email, 'Adresse email', _userEmail ?? ''),
                    _buildDivider(),
                    _buildInfoRow(Icons.phone, 'Téléphone', _company?['mobile_money_number'] ?? '+229 97 12 34 56'),
                    _buildDivider(),
                    _buildInfoRow(Icons.location_on, 'Ville & pays', _company?['city'] ?? 'Cotonou, Bénin'),
                    _buildDivider(),
                    _buildInfoRow(Icons.badge, 'Numéro IFU / NIF', _company?['ifu_nif'] ?? 'BJ-2023-00412'),
                  ]),

                  const SizedBox(height: 24),

                  // ==========================================
                  // MOBILE MONEY
                  // ==========================================
                  _buildSectionTitle('MOBILE MONEY'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.phone_android,
                      'Numéro principal',
                      '${_company?['mobile_money_operator'] ?? 'MTN'} · ${_company?['mobile_money_number'] ?? '97 12 34 56'}',
                      badge: 'Principal',
                      badgeColor: kGreen,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      Icons.phone,
                      'Numéro secondaire',
                      'Ajouter Moov Money',
                      isAction: true,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ==========================================
                  // LOGO
                  // ==========================================
                  _buildSectionTitle('MON LOGO'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: kLightBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(Icons.image_outlined, color: kGrayText, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Logo entreprise',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Apparaît sur tes factures PDF',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: kGrayText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Modifier',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: kDarkBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: kGrayText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {
    String? badge,
    Color? badgeColor,
    bool isAction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kDarkBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kDarkBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: kGrayText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isAction ? kDarkBlue : Colors.black87,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? kGrayText).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor ?? kGrayText,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isAction)
            const Icon(Icons.chevron_right, color: kGrayText, size: 20),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200, indent: 64);
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: kDarkBlue,
      unselectedItemColor: kGrayText,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      currentIndex: currentIndex,
      onTap: (index) {
        final screens = [
          const DashboardScreen(),
          const ClientsScreen(),
          const InvoicesScreen(),
          const AssistantScreen(),
        ];
        if (index < screens.length) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screens[index]));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
        BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Factures'),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'Assistant'),
      ],
    );
  }
}