import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_service.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightBlue = Color(0xFFF0F9FF);
const Color kInputBorder = Color(0xFFD1D5DB);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ifuController = TextEditingController();
  final _sectorController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _ifuController.dispose();
    _sectorController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await DataService.getUserProfile(user.id);
      final company = await DataService.getCompany(user.id);

      setState(() {
        _firstNameController.text = profile?['first_name'] ?? '';
        _lastNameController.text = profile?['last_name'] ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = company?['mobile_money_number'] ?? '';
        _companyNameController.text = company?['name'] ?? '';
        _addressController.text = company?['city'] ?? '';
        _ifuController.text = company?['ifu_nif'] ?? '';
        _sectorController.text = company?['sector'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement : $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Utilisateur non connecté';
      });
      return;
    }

    try {
      // Mettre à jour le profil
      await Supabase.instance.client
          .from('profiles')
          .update({
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
          })
          .eq('id', user.id);

      // Mettre à jour l'entreprise
      await Supabase.instance.client
          .from('companies')
          .update({
            'name': _companyNameController.text.trim(),
            'city': _addressController.text.trim(),
            'ifu_nif': _ifuController.text.trim(),
            'sector': _sectorController.text.trim(),
            'mobile_money_number': _phoneController.text.trim(),
          })
          .eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil mis à jour avec succès'),
            backgroundColor: kGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        title: Text(
          'Modifier le profil',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Sauver',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kDarkBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: kDarkBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_firstNameController.text.isNotEmpty ? _firstNameController.text[0] : 'K'}${_lastNameController.text.isNotEmpty ? _lastNameController.text[0] : 'M'}',
                          style: GoogleFonts.novaFlat(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt, color: kDarkBlue, size: 16),
                      label: Text(
                        'Modifier le logo',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kDarkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Message d'erreur
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==========================================
                  // PROFIL PERSONNEL
                  // ==========================================
                  _buildSectionTitle('PROFIL PERSONNEL'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Prénom & Nom',
                    controller: _firstNameController,
                    hintText: 'Kofi Mensah',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'kofi@kofidesign.bj',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Téléphone',
                    controller: _phoneController,
                    hintText: '+229 97 12 34 56',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // ENTREPRISE
                  // ==========================================
                  _buildSectionTitle('ENTREPRISE'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Nom entreprise',
                    controller: _companyNameController,
                    hintText: 'Kofi Design Studio',
                    icon: Icons.business,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Adresse',
                    controller: _addressController,
                    hintText: 'Rue des Cocotiers, Cotonou',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'IFU / NIF',
                    controller: _ifuController,
                    hintText: 'BJ-2023-00412',
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Secteur d\'activité',
                    controller: _sectorController,
                    hintText: 'Design & Développement web',
                    icon: Icons.work,
                  ),

                  const SizedBox(height: 24),

                  // Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kLightBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kDarkBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: kDarkBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ces informations apparaîtront automatiquement sur toutes tes futures factures PDF.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: kDarkBlue,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton Enregistrer
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDarkBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Enregistrer les modifications',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kGrayText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
            prefixIcon: Icon(icon, color: kGrayText, size: 20),
            filled: true,
            fillColor: enabled ? Colors.white : kLightBlue,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kInputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kInputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kDarkBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}