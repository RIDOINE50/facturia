import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KKiaPayService {
  // 🔑 TES CLÉS KKiaPay SANDBOX
  static const String _apiKey = '020040706f4a11f19884f9f71239858c';
  static const String _secret = 'tsk_020067826f4a11f19884f9f71239858c';
  
  // URL de l'API KKiaPay
  static const String _baseUrl = 'https://api.kkiapay.me/api';

  /// Génère l'URL de paiement KKiaPay
  static Future<String?> generatePaymentUrl({
    required int amount,
    required String transactionId,
    required String description,
  }) async {
    try {
      // KKiaPay utilise une URL simple pour les paiements
      // Format : https://app.kkiapay.me/p/{apiKey}?amount=X&reason=Y&data=Z
      final encodedReason = Uri.encodeComponent(description);
      final encodedData = Uri.encodeComponent('{"transaction_id":"$transactionId"}');
      
      return 'https://app.kkiapay.me/p/$_apiKey?amount=$amount&reason=$encodedReason&data=$encodedData';
    } catch (e) {
      print('❌ Erreur génération URL : $e');
      return null;
    }
  }

  /// Sauvegarde un paiement en attente
  static Future<void> savePendingPayment({
    required String userId,
    required int amount,
    required String plan,
    required String transactionId,
  }) async {
    try {
      final client = Supabase.instance.client;
      await client.from('payments').insert({
        'user_id': userId,
        'amount': amount,
        'plan': plan,
        'transaction_id': transactionId,
        'status': 'pending',
      });
    } catch (e) {
      print('❌ Erreur sauvegarde paiement : $e');
    }
  }

  /// Met à jour le statut d'un paiement
  static Future<void> updatePaymentStatus({
    required String transactionId,
    required String status,
  }) async {
    try {
      final client = Supabase.instance.client;
      
      await client
          .from('payments')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('transaction_id', transactionId);

      if (status == 'success' || status == 'approved') {
        final payment = await client
            .from('payments')
            .select()
            .eq('transaction_id', transactionId)
            .single();
        
        final userId = payment['user_id'];
        final plan = payment['plan'];
        
        await client
            .from('profiles')
            .update({'plan': plan})
            .eq('id', userId);
        
        print('✅ Plan $plan activé pour user $userId');
      }
    } catch (e) {
      print('❌ Erreur mise à jour paiement : $e');
    }
  }

  /// Vérifie le statut d'un paiement via l'API KKiaPay
  static Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reverse'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_secret',
        },
        body: jsonEncode({'transactionId': transactionId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['status'] ?? 'unknown',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur serveur: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Erreur vérification paiement : $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }
}