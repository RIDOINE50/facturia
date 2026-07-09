
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class AIService {
  // 🔑 REMPLACE PAR TA CLÉ GROQ (gsk_...)
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  static const Map<String, int> _limits = {
    'free': 10,
    'starter': 100,
    'pro': -1,
  };
static Future<Map<String, dynamic>> checkUsage(String userId) async {
  try {
    final client = Supabase.instance.client;

    // Récupérer le profil COMPLET (role + plan)
    final profile = await client
        .from('profiles')
        .select('role, plan')
        .eq('id', userId)
        .single();

    final role = profile['role'] ?? 'user';
    final plan = profile['plan'] ?? 'free'; // ← NOUVEAU : on regarde le plan

    // Déterminer la limite selon le plan
    int limit;
    if (role == 'admin' || plan == 'pro') {
      limit = -1; // Illimité pour les admins et plan Pro
    } else if (plan == 'starter') {
      limit = 100; // 100 messages pour le plan Starter
    } else {
      limit = 10; // 10 messages pour le plan Free
    }

    // Compter les messages ce mois
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);

    final count = await client
        .from('ai_conversations')
        .select('id')
        .eq('user_id', userId)
        .gte('created_at', firstOfMonth.toIso8601String());

    final used = count.length;
    final remaining = limit == -1 ? -1 : limit - used;

    return {
      'plan': plan,
      'limit': limit,
      'used': used,
      'remaining': remaining,
      'canUse': limit == -1 || used < limit,
    };
  } catch (e) {
    print('❌ Erreur vérification usage : $e');
    return {'canUse': false, 'error': e.toString()};
  }
}

  static Future<String> askQuestion(
    String userId,
    String question, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final usage = await checkUsage(userId);
      if (!usage['canUse']) {
        return '❌ Tu as atteint ta limite de ${usage['limit']} messages ce mois-ci.\n\n💡 Passe au plan **Starter** (100 messages) ou **Pro** (illimité) pour continuer.';
      }

      final messages = <Map<String, dynamic>>[];

      // Message système
      messages.add({
        'role': 'system',
        'content': '''Tu es FACTURIA AI, un assistant intelligent et polyvalent créé pour aider les entrepreneurs du Bénin et d'Afrique.

Tu peux répondre à TOUTES les questions :
- Facturation, comptabilité, TVA, IFU
- Business, marketing, gestion
- Questions générales, culture, éducation
- Conseils pratiques, vie quotidienne
- Et bien plus encore !

Sois :
- Clair et concis
- Pratique et utile
- Respectueux et professionnel
- Adapté au contexte africain quand c'est pertinent

Réponds en français, de manière naturelle et conversationnelle.''',
      });

      // Historique
      if (conversationHistory != null) {
        for (final msg in conversationHistory) {
          messages.add({
            'role': msg['role'],
            'content': msg['content'],
          });
        }
      }

      // Nouvelle question
      messages.add({
        'role': 'user',
        'content': question,
      });

      // Appel API Groq
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'];
        final tokensUsed = data['usage']?['total_tokens'] ?? 0;

        await _saveConversation(userId, question, answer, tokensUsed);
        return answer;
      } else {
        print('❌ Erreur API Groq : ${response.statusCode} - ${response.body}');
        return '❌ Désolé, je rencontre un problème technique. Réessaie dans quelques instants.';
      }
    } catch (e) {
      print('❌ Erreur appel IA : $e');
      return '❌ Erreur de connexion. Vérifie ta connexion internet et réessaie.';
    }
  }

  static Future<void> _saveConversation(
    String userId,
    String question,
    String answer,
    int tokensUsed,
  ) async {
    try {
      final client = Supabase.instance.client;
      await client.from('ai_conversations').insert({
        'user_id': userId,
        'question': question,
        'answer': answer,
        'tokens_used': tokensUsed,
        'cost_fcfa': 0,
      });
    } catch (e) {
      print('❌ Erreur sauvegarde : $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('ai_conversations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('❌ Erreur récupération historique : $e');
      return [];
    }
  }

  static Future<void> clearHistory(String userId) async {
    try {
      final client = Supabase.instance.client;
      await client
          .from('ai_conversations')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('❌ Erreur suppression historique : $e');
    }
  }
}