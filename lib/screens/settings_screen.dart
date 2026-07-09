import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _company;
  bool _isLoading = true;
  
  // Préférences utilisateur
  bool _isDarkMode = false;
  String _currentLanguage = 'Français';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPreferences();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final company = await Supabase.instance.client
          .from('companies')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        _profile = profile;
        _company = company;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement profil : $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _currentLanguage = prefs.getString('language') ?? 'Français';
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      _isDarkMode = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? '🌙 Mode sombre activé' : '☀️ Mode clair activé'),
          backgroundColor: kDarkBlue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showLanguageDialog() async {
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choisir la langue',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Français', '🇫🇷'),
            const SizedBox(height: 8),
            _buildLanguageOption('English', '🇬🇧'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedLanguage != null && selectedLanguage != _currentLanguage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', selectedLanguage);
      setState(() {
        _currentLanguage = selectedLanguage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Langue changée : $selectedLanguage'),
            backgroundColor: kGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildLanguageOption(String language, String flag) {
    final isSelected = _currentLanguage == language;
    return InkWell(
      onTap: () => Navigator.pop(context, language),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kDarkBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kDarkBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? kDarkBlue : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kDarkBlue, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Se déconnecter ?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Vous devrez vous reconnecter pour accéder à votre compte.',
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
              backgroundColor: kRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.signOut();
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Paramètres',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kDarkBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // SECTION COMPTE
                  // ==========================================
                  _buildSectionTitle('COMPTE'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      iconColor: kDarkBlue,
                      title: 'Mon profil',
                      subtitle: 'Nom, email, logo, IFU',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      iconColor: kDarkBlue,
                      title: 'Sécurité',
                      subtitle: 'Mot de passe, 2FA',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.credit_card,
                      iconColor: kOrange,
                      title: 'Abonnement',
                      subtitle: 'Plan Pro · 7 000 FCFA/mois',
                      badge: 'Pro',
                      badgeColor: kOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ==========================================
                  // SECTION FACTURATION
                  // ==========================================
                  _buildSectionTitle('FACTURATION'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.description_outlined,
                      iconColor: kDarkBlue,
                      title: 'Modèle de facture',
                      subtitle: 'Couleurs, logo, pied de page',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.attach_money,
                      iconColor: kGreen,
                      title: 'Devise',
                      subtitle: 'FCFA (XOF)',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ==========================================
                  // SECTION NOTIFICATIONS
                  // ==========================================
                  _buildSectionTitle('NOTIFICATIONS'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.notifications_outlined,
                      iconColor: kOrange,
                      title: 'Rappels de paiement',
                      subtitle: 'Notifications push',
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {},
                        activeColor: kDarkBlue,
                      ),
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ==========================================
                  // SECTION APPLICATION
                  // ==========================================
                  _buildSectionTitle('APPLICATION'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      iconColor: kDarkBlue,
                      title: 'Mode sombre',
                      subtitle: 'Thème de l\'interface',
                      trailing: Switch(
                        value: _isDarkMode,
                        onChanged: _toggleDarkMode,
                        activeColor: kDarkBlue,
                      ),
                      onTap: () => _toggleDarkMode(!_isDarkMode),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.language,
                      iconColor: kDarkBlue,
                      title: 'Langue',
                      subtitle: _currentLanguage,
                      onTap: _showLanguageDialog,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ==========================================
                  // SECTION AIDE & SUPPORT
                  // ==========================================
                  _buildSectionTitle('AIDE & SUPPORT'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      iconColor: kDarkBlue,
                      title: 'FAQ',
                      subtitle: 'Questions fréquentes',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // ==========================================
                  // BOUTON DÉCONNEXION
                  // ==========================================
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: kRed),
                      label: Text(
                        'Se déconnecter',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kRed,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kRed),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // VERSION DE L'APP
                  // ==========================================
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'FactuRIA v1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: kGrayText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cotonou, Bénin 🇧🇯',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: kGrayText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
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

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: kGrayText,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_right, color: kGrayText, size: 20),
          ],
        ),
      ),
    );
  }
}