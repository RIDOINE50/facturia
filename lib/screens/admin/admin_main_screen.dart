import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_invoices_screen.dart';
import 'admin_subscriptions_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_ai_screen.dart';
import 'admin_settings_screen.dart';
import '../login_screen.dart';


const Color kSidebarBg = Color(0xFF1E3A8A);
const Color kBgColor = Color(0xFFF3F4F6);
const Color kOrange = Color(0xFFF59E0B);

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminInvoicesScreen(),
    AdminSubscriptionsScreen(),
    AdminStatsScreen(),
    AdminAIScreen(),
    AdminSettingsScreen(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Tableau de bord'},
    {'icon': Icons.people, 'label': 'Utilisateurs'},
    {'icon': Icons.description, 'label': 'Factures'},
    {'icon': Icons.credit_card, 'label': 'Abonnements'},
    {'icon': Icons.analytics, 'label': 'Statistiques'},
    {'icon': Icons.smart_toy, 'label': 'Assistant IA'},
    {'icon': Icons.settings, 'label': 'Paramètres'},
  ];

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text('Se déconnecter ?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Vous serez redirigé vers l\'écran de connexion.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Se déconnecter',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 260,
            color: kSidebarBg,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Factu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            TextSpan(text: 'RIA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Administration',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                  ),
                ),
                const Divider(color: Colors.white24, height: 30),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return ListTile(
                        leading: Icon(_menuItems[index]['icon'], color: isSelected ? Colors.white : Colors.white70),
                        title: Text(
                          _menuItems[index]['label'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),

                // PROFIL ADMIN + BOUTON DÉCONNEXION
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black.withOpacity(0.2),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                            child: const Text('SA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Super Admin', style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                                Text('admin@facturia.bj', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout, color: Colors.white, size: 16),
                          label: Text(
                            'Se déconnecter',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}