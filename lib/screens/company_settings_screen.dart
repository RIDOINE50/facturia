import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  File? _logoFile;
  File? _stampFile;
  bool _isSaving = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (type == 'logo') _logoFile = File(pickedFile.path);
        if (type == 'stamp') _stampFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveToSupabase() async {
    setState(() => _isSaving = true);
    print('🔍 [SAVE] Début sauvegarde...');
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Non connecté');

      const bucket = 'company-assets';
      final userId = user.id;
      print('🔍 [SAVE] User ID: $userId');

      String? logoUrl;
      String? signatureUrl;
      String? stampUrl;

      // 1. Upload Logo
      if (_logoFile != null) {
        print('🔍 [SAVE] Upload logo...');
        final ext = path.extension(_logoFile!.path);
        final filePath = '$userId/logo$ext';
        
        try {
          await Supabase.instance.client.storage.from(bucket).upload(
            filePath,
            _logoFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          print('✅ [SAVE] Logo uploadé');
          
          // CORRECTION : getPublicUrl retourne une String directement
          logoUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(filePath);
          print('✅ [SAVE] Logo URL: $logoUrl');
        } catch (e) {
          print('❌ [SAVE] Erreur upload logo: $e');
        }
      } else {
        print('⚠️ [SAVE] Pas de logo à uploader');
      }

      // 2. Upload Signature
      print('🔍 [SAVE] Upload signature...');
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes != null && signatureBytes.isNotEmpty) {
        print('✅ [SAVE] Signature bytes: ${signatureBytes.length} bytes');
        final filePath = '$userId/signature.png';
        
        try {
          await Supabase.instance.client.storage.from(bucket).uploadBinary(
            filePath,
            signatureBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          print('✅ [SAVE] Signature uploadée');
          
          signatureUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(filePath);
          print('✅ [SAVE] Signature URL: $signatureUrl');
        } catch (e) {
          print('❌ [SAVE] Erreur upload signature: $e');
        }
      } else {
        print('⚠️ [SAVE] Pas de signature à uploader (bytes null ou vide)');
      }

      // 3. Upload Cachet
      if (_stampFile != null) {
        print('🔍 [SAVE] Upload cachet...');
        final ext = path.extension(_stampFile!.path);
        final filePath = '$userId/stamp$ext';
        
        try {
          await Supabase.instance.client.storage.from(bucket).upload(
            filePath,
            _stampFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          print('✅ [SAVE] Cachet uploadé');
          
          stampUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(filePath);
          print('✅ [SAVE] Cachet URL: $stampUrl');
        } catch (e) {
          print('❌ [SAVE] Erreur upload cachet: $e');
        }
      } else {
        print('⚠️ [SAVE] Pas de cachet à uploader');
      }

      // 4. Sauvegarder les URLs dans la table 'profiles'
      print('🔍 [SAVE] Sauvegarde dans profiles...');
      print('🔍 [SAVE] Logo: $logoUrl');
      print('🔍 [SAVE] Signature: $signatureUrl');
      print('🔍 [SAVE] Cachet: $stampUrl');
      
      final response = await Supabase.instance.client
          .from('profiles')
          .update({
            'logo_url': logoUrl,
            'signature_url': signatureUrl,
            'stamp_url': stampUrl,
          })
          .eq('id', userId)
          .select();
      
      print('✅ [SAVE] Réponse Supabase: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Paramètres sauvegardés !\nLogo: ${logoUrl != null ? "OK" : "NULL"}')),
        );
      }
    } catch (e) {
      print('❌ [SAVE] Erreur générale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identité de l\'entreprise'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('LOGO'),
            const SizedBox(height: 10),
            _buildImagePreview(_logoFile, 'Choisir un logo', () => _pickImage('logo')),

            const SizedBox(height: 30),
            _buildSectionTitle('SIGNATURE'),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _signatureController.clear(),
              icon: const Icon(Icons.clear, color: Colors.red),
              label: const Text('Effacer la signature', style: TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 30),
            _buildSectionTitle('CACHET'),
            const SizedBox(height: 10),
            _buildImagePreview(_stampFile, 'Choisir un cachet', () => _pickImage('stamp')),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveToSupabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(' Sauvegarder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 1));
  }

  Widget _buildImagePreview(File? file, String placeholder, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: file != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(file, fit: BoxFit.contain))
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(placeholder, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
      ),
    );
  }
}