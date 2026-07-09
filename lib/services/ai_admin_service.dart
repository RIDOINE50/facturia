import 'package:supabase_flutter/supabase_flutter.dart';

class AIAdminService {
  static Future<List<Map<String, dynamic>>> getAllConversations({int limit = 100}) async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('ai_conversations')
          .select('*, profiles(first_name, last_name, email)')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('❌ Erreur récupération conversations : $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAIStats() async {
    try {
      final client = Supabase.instance.client;
      final now = DateTime.now();
      final firstOfMonth = DateTime(now.year, now.month, 1);

      final messagesThisMonth = await client
          .from('ai_conversations')
          .select('id')
          .gte('created_at', firstOfMonth.toIso8601String());

      final costs = await client
          .from('ai_conversations')
          .select('cost_fcfa')
          .gte('created_at', firstOfMonth.toIso8601String());

      final totalCost = costs.fold<int>(0, (sum, c) => sum + (c['cost_fcfa'] as int? ?? 0));

      final allMessages = await client.from('ai_conversations').select('id');

      final uniqueUsers = await client.from('ai_conversations').select('user_id');
      final uniqueUserIds = uniqueUsers.map((m) => m['user_id']).toSet();

      final recentMessages = await client
          .from('ai_conversations')
          .select('question')
          .gte('created_at', firstOfMonth.toIso8601String());

      int tvaCount = 0, factureCount = 0, businessCount = 0;
      for (final msg in recentMessages) {
        final q = (msg['question'] ?? '').toLowerCase();
        if (q.contains('tva') || q.contains('ifu') || q.contains('impôt')) tvaCount++;
        if (q.contains('facture') || q.contains('client') || q.contains('paiement')) factureCount++;
        if (q.contains('business') || q.contains('entreprise') || q.contains('vente')) businessCount++;
      }

      return {
        'messagesThisMonth': messagesThisMonth.length,
        'totalCost': totalCost,
        'totalMessages': allMessages.length,
        'uniqueUsers': uniqueUserIds.length,
        'topics': {
          'TVA/Fiscalité': tvaCount,
          'Facturation': factureCount,
          'Business': businessCount,
        },
      };
    } catch (e) {
      print('❌ Erreur stats IA : $e');
      return {'messagesThisMonth': 0, 'totalCost': 0, 'totalMessages': 0, 'uniqueUsers': 0, 'topics': {}};
    }
  }
}