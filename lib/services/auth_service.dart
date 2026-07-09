import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // INSCRIPTION
  // ==========================================
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone ?? '',
        },
      );

      if (response.user == null) {
        throw Exception('Impossible de créer le compte');
      }

      print('✅ Utilisateur créé : ${response.user!.email}');
      return response;
    } on AuthException catch (e) {
      print('❌ Erreur Auth signup : ${e.message}');
      throw Exception('Erreur Auth : ${e.message}');
    } catch (e) {
      print('❌ Erreur signup : $e');
      throw Exception('Erreur : $e');
    }
  }

  // ==========================================
  // CONNEXION (avec logs détaillés)
  // ==========================================
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔍 Tentative de connexion pour : $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('❌ User null après connexion');
        throw Exception('Email ou mot de passe incorrect');
      }

      print('✅ Connecté : ${response.user!.email}');
      print('✅ User ID : ${response.user!.id}');
      return response;
    } on AuthException catch (e) {
      print('❌ ERREUR AUTH EXACTE : ${e.message}');
      print('❌ Code erreur : ${e.statusCode}');
      throw Exception('Erreur : ${e.message}');
    } catch (e) {
      print('❌ ERREUR INCONNUE : $e');
      throw Exception('Erreur : $e');
    }
  }

  // ==========================================
  // DÉCONNEXION
  // ==========================================
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ==========================================
  // RÉCUPÉRER L'UTILISATEUR ACTUEL
  // ==========================================
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // ==========================================
  // VÉRIFIER SI L'UTILISATEUR EST ADMIN (avec logs)
  // ==========================================
  static Future<bool> isAdmin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('❌ isAdmin: user null');
        return false;
      }

      print('🔍 isAdmin: vérification pour user ${user.id}');

      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      print('📊 isAdmin: réponse = $response');

      if (response == null) {
        print('❌ isAdmin: pas de profil trouvé');
        return false;
      }
      
      final role = response['role'];
      print('👤 isAdmin: rôle = $role');
      
      return role == 'admin';
    } catch (e) {
      print('❌ ERREUR isAdmin : $e');
      return false;
    }
  }

  // ==========================================
  // RÉCUPÉRER LE RÔLE DE L'UTILISATEUR
  // ==========================================
  static Future<String?> getUserRole() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      print('❌ Erreur récupération rôle : $e');
      return null;
    }
  }

  // ==========================================
  // CONNEXION + VÉRIFICATION RÔLE (méthode complète)
  // ==========================================
  static Future<Map<String, dynamic>> signInAndCheckRole({
    required String email,
    required String password,
  }) async {
    try {
      print('🔍 signInAndCheckRole: début pour $email');
      
      // 1. Connexion
      final authResponse = await signIn(email: email, password: password);
      
      if (authResponse.user == null) {
        throw Exception('Connexion échouée');
      }

      print('✅ Connexion réussie, vérification du rôle...');

      // 2. Vérifier le rôle
      final isAdminUser = await isAdmin();
      
      print('✅ Rôle vérifié : admin = $isAdminUser');

      return {
        'success': true,
        'user': authResponse.user,
        'isAdmin': isAdminUser,
      };
    } catch (e) {
      print('❌ signInAndCheckRole erreur : $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==========================================
  // COMPLÉTER LE PROFIL (Entreprise + Mobile Money)
  // ==========================================
  static Future<void> completeProfile({
    required String userId,
    String? companyName,
    String? sector,
    String? city,
    String? ifuNif,
    String? mobileMoneyOperator,
    String? mobileMoneyNumber,
  }) async {
    try {
      await _client.from('companies').insert({
        'user_id': userId,
        'name': companyName ?? 'Mon Entreprise',
        'sector': sector,
        'city': city,
        'ifu_nif': ifuNif,
        'mobile_money_operator': mobileMoneyOperator,
        'mobile_money_number': mobileMoneyNumber,
      });

      print('✅ Profil complété');
    } catch (e) {
      print('❌ Erreur profil : $e');
      throw Exception('Erreur lors de la sauvegarde du profil');
    }
  }

  // ==========================================
  // RÉCUPÉRER LE PROFIL COMPLET
  // ==========================================
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final companyResponse = await _client
          .from('companies')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return {
        'profile': profileResponse,
        'company': companyResponse,
      };
    } catch (e) {
      print('❌ Erreur récupération profil : $e');
      return null;
    }
  }

  // ==========================================
  // METTRE À JOUR MOBILE MONEY
  // ==========================================
  static Future<void> updateMobileMoney({
    required String userId,
    required String operator,
    required String number,
  }) async {
    try {
      await _client.from('companies').update({
        'mobile_money_operator': operator,
        'mobile_money_number': number,
      }).eq('user_id', userId);

      print('✅ Mobile Money mis à jour');
    } catch (e) {
      print('❌ Erreur Mobile Money : $e');
      throw Exception('Erreur lors de la sauvegarde du numéro Mobile Money');
    }
  }

  // ==========================================
  // METTRE À JOUR LE RÔLE D'UN UTILISATEUR (Admin seulement)
  // ==========================================
  static Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      final isAdminUser = await isAdmin();
      if (!isAdminUser) {
        throw Exception('Seuls les administrateurs peuvent modifier les rôles');
      }

      await _client.from('profiles').update({
        'role': role,
      }).eq('id', userId);

      print('✅ Rôle mis à jour : $role');
    } catch (e) {
      print('❌ Erreur mise à jour rôle : $e');
      throw Exception('Erreur lors de la mise à jour du rôle');
    }
  }

  // ==========================================
  // RÉCUPÉRER TOUS LES UTILISATEURS (Admin seulement)
  // ==========================================
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final isAdminUser = await isAdmin();
      if (!isAdminUser) {
        throw Exception('Accès refusé : administrateurs uniquement');
      }

      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération utilisateurs : $e');
      return [];
    }
  }

  // ==========================================
  // METTRE À JOUR LE PROFIL (Prénom, Nom)
  // ==========================================
  static Future<void> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;

      if (updateData.isNotEmpty) {
        await _client.from('profiles').update(updateData).eq('id', userId);
        print('✅ Profil mis à jour');
      }
    } catch (e) {
      print('❌ Erreur mise à jour profil : $e');
      throw Exception('Erreur lors de la mise à jour du profil');
    }
  }

  // ==========================================
  // METTRE À JOUR L'ENTREPRISE
  // ==========================================
  static Future<void> updateCompany({
    required String userId,
    String? name,
    String? sector,
    String? city,
    String? ifuNif,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (sector != null) updateData['sector'] = sector;
      if (city != null) updateData['city'] = city;
      if (ifuNif != null) updateData['ifu_nif'] = ifuNif;

      if (updateData.isNotEmpty) {
        await _client.from('companies').update(updateData).eq('user_id', userId);
        print('✅ Entreprise mise à jour');
      }
    } catch (e) {
      print('❌ Erreur mise à jour entreprise : $e');
      throw Exception('Erreur lors de la mise à jour de l\'entreprise');
    }
  }

  // ==========================================
  // CHANGER LE MOT DE PASSE
  // ==========================================
  static Future<void> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      print('✅ Mot de passe changé');
    } catch (e) {
      print('❌ Erreur changement mot de passe : $e');
      throw Exception('Erreur lors du changement de mot de passe');
    }
  }
}