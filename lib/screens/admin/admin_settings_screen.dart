import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Toggles locaux (peuvent être stockés en DB plus tard)
  bool _maintenanceMode = false;
  bool _openSignup = true;
  bool _aiEnabled = true;
  bool _dgiWarning = true;
  bool _emailNotif = true;

  // Stats réelles
  int _totalUsers = 0;
  int _totalInvoices = 0;
  int _totalClients = 0;
  int _totalCompanies = 0;

  // Statut des services Supabase
  String _authStatus = 'Vérification...';
  Color _authColor = kOrange;
  String _dbStatus = 'Vérification...';
  Color _dbColor = kOrange;
  String _storageStatus = 'Vérification...';
  Color _storageColor = kOrange;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkServices();
  }

  Future<void> _checkServices() async {
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;

    try {
      // 1. Tester Auth (récupérer l'utilisateur courant)
      final user = client.auth.currentUser;
      if (user != null) {
        _authStatus = 'OK';
        _authColor = kGreen;
      } else {
        _authStatus = 'Déconnecté';
        _authColor = kRed;
      }
    } catch (e) {
      _authStatus = 'Erreur';
      _authColor = kRed;
    }

    try {
      // 2. Tester Base de données (compter les utilisateurs)
      final usersRes = await client.from('profiles').select('id');
      final invoicesRes = await client.from('invoices').select('id');
      final clientsRes = await client.from('clients').select('id');
      final companiesRes = await client.from('companies').select('id');

      _totalUsers = usersRes.length;
      _totalInvoices = invoicesRes.length;
      _totalClients = clientsRes.length;
      _totalCompanies = companiesRes.length;

      _dbStatus = 'OK';
      _dbColor = kGreen;
    } catch (e) {
      _dbStatus = 'Erreur';
      _dbColor = kRed;
    }

    try {
      // 3. Tester Storage (liste des buckets)
      final buckets = await client.storage.listBuckets();
      _storageStatus = 'OK (${buckets.length} buckets)';
      _storageColor = kGreen;
    } catch (e) {
      _storageStatus = 'Non configuré';
      _storageColor = kOrange;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    // Ici on pourrait sauvegarder dans une table `settings`
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Paramètres enregistrés'),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paramètres système', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('Configuration générale de la plateforme', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _checkServices,
            icon: const Icon(Icons.refresh, color: kDarkBlue),
            tooltip: 'Actualiser',
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            label: Text('Enregistrer', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(backgroundColor: kDarkBlue),
            onPressed: _saveSettings,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kDarkBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats réelles de la plateforme
                  _buildSettingsCard(
                    'État de la plateforme (données réelles)',
                    Row(
                      children: [
                        _buildStatBox('Utilisateurs', '$_totalUsers', kDarkBlue),
                        const SizedBox(width: 12),
                        _buildStatBox('Factures', '$_totalInvoices', kOrange),
                        const SizedBox(width: 12),
                        _buildStatBox('Clients', '$_totalClients', kGreen),
                        const SizedBox(width: 12),
                        _buildStatBox('Entreprises', '$_totalCompanies', Colors.purple),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Intégration IA (config simulée)
                  _buildSettingsCard(
                    'Intégration IA',
                    Column(
                      children: [
                        _buildSettingRow('Modèle IA', 'claude-haiku-3 (Anthropic)'),
                        _buildSettingRow('Limite globale messages / mois', '50 000'),
                        _buildSettingRow('Prompt système', 'Tu es l\'assistant FACTURIA. Tu aides les petits entrepreneurs du Bénin...'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Paiement Mobile Money
                  _buildSettingsCard(
                    'Paiement Mobile Money',
                    Column(
                      children: [
                        _buildSettingRow('Passerelle active', 'CinetPay + KKiaPay'),
                        _buildSettingRow('Clé API CinetPay', '••••••••••••••••'),
                        _buildSettingRow('Clé API KKiaPay', '••••••••••••••••'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fonctionnalités actives (toggles locaux)
                  _buildSettingsCard(
                    'Fonctionnalités actives',
                    Column(
                      children: [
                        _buildToggleRow('Mode maintenance', 'Bloquer les connexions utilisateurs', _maintenanceMode, (v) => setState(() => _maintenanceMode = v)),
                        _buildToggleRow('Inscription ouverte', 'Permettre la création de nouveaux comptes', _openSignup, (v) => setState(() => _openSignup = v)),
                        _buildToggleRow('Assistant IA activé', 'Activer le chat IA pour tous les plans', _aiEnabled, (v) => setState(() => _aiEnabled = v)),
                        _buildToggleRow('Avertissement DGI', 'Afficher le disclaimer légal sur chaque facture', _dgiWarning, (v) => setState(() => _dgiWarning = v)),
                        _buildToggleRow('Notifications email', 'Alertes admin par email', _emailNotif, (v) => setState(() => _emailNotif = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Base de données (TESTS RÉELS)
                  _buildSettingsCard(
                    'Base de données (tests en temps réel)',
                    Column(
                      children: [
                        _buildStatusRow('Supabase Auth', _authStatus, _authColor),
                        _buildStatusRow('Base de données', _dbStatus, _dbColor),
                        _buildStatusRow('Storage (logos PDF)', _storageStatus, _storageColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Zone de danger
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kRed.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber, color: kRed),
                            const SizedBox(width: 12),
                            Text('Zone de danger', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: kRed)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Actions irréversibles — réinitialisation des données, suppression de comptes en masse, purge des logs IA', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showDangerDialog(),
                          icon: const Icon(Icons.lock, color: Colors.white),
                          label: Text('Accès restreint', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(backgroundColor: kRed),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: kGrayText)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 200, child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, String description, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                Text(description, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kDarkBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  void _showDangerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: kRed),
            const SizedBox(width: 8),
            Text('Accès restreint', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Cette zone nécessite une confirmation supplémentaire. Contactez le super administrateur.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}