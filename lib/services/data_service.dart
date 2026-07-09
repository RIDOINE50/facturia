import 'package:supabase_flutter/supabase_flutter.dart';

class DataService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // RÉCUPÉRER LE PROFIL UTILISATEUR
  // ==========================================
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('❌ Erreur récupération profil : $e');
      return null;
    }
  }

  // ==========================================
  // RÉCUPÉRER L'ENTREPRISE
  // ==========================================
  // ==========================================
  // RÉCUPÉRER L'ENTREPRISE
  // ==========================================
  static Future<Map<String, dynamic>?> getCompany(String userId) async {
    try {
      final response = await _client
          .from('companies')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Erreur récupération entreprise : $e');
      return null;
    }
  }

  // ==========================================
  // RÉCUPÉRER LES STATS DU DASHBOARD
  // ==========================================
  static Future<Map<String, dynamic>> getDashboardStats(String userId) async {
    try {
      // Récupérer toutes les factures de l'utilisateur
      final invoicesResponse = await _client
          .from('invoices')
          .select()
          .eq('user_id', userId);

      final invoices = invoicesResponse as List<dynamic>;

      // Calculer les stats
      int totalInvoices = invoices.length;
      int paidCount = 0;
      int pendingCount = 0;
      int overdueCount = 0;
      double paidAmount = 0;
      double pendingAmount = 0;
      double totalMonthAmount = 0;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var invoice in invoices) {
        final status = invoice['status'];
        final amount = (invoice['total_amount'] ?? 0).toDouble();
        final issueDate = DateTime.parse(invoice['issue_date']);

        // Factures du mois
        if (issueDate.isAfter(startOfMonth)) {
          totalMonthAmount += amount;
        }

        // Stats par statut
        if (status == 'paid') {
          paidCount++;
          paidAmount += amount;
        } else if (status == 'sent') {
          pendingCount++;
          pendingAmount += amount;
        } else if (status == 'overdue') {
          overdueCount++;
        }
      }

      // Récupérer le nombre de clients
      final clientsResponse = await _client
          .from('clients')
          .select()
          .eq('user_id', userId);

      final clients = clientsResponse as List<dynamic>;

      return {
        'totalInvoices': totalInvoices,
        'paidCount': paidCount,
        'pendingCount': pendingCount,
        'overdueCount': overdueCount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'totalMonthAmount': totalMonthAmount,
        'totalClients': clients.length,
      };
    } catch (e) {
      print('❌ Erreur récupération stats : $e');
      return {
        'totalInvoices': 0,
        'paidCount': 0,
        'pendingCount': 0,
        'overdueCount': 0,
        'paidAmount': 0.0,
        'pendingAmount': 0.0,
        'totalMonthAmount': 0.0,
        'totalClients': 0,
      };
    }
  }

  // ==========================================
  // RÉCUPÉRER LES DERNIÈRES FACTURES
  // ==========================================
  static Future<List<Map<String, dynamic>>> getRecentInvoices(String userId, {int limit = 3}) async {
    try {
      final response = await _client
          .from('invoices')
          .select('*, clients(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération factures récentes : $e');
      return [];
    }
  }

  // ==========================================
  // RÉCUPÉRER TOUS LES CLIENTS DE L'UTILISATEUR
  // ==========================================
  static Future<List<Map<String, dynamic>>> getAllClients(String userId) async {
    try {
      final response = await _client
          .from('clients')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération clients : $e');
      return [];
    }
  }

  // ==========================================
  // CALCULER LE TOTAL FACTURÉ PAR CLIENT
  // ==========================================
  static Future<Map<String, dynamic>> getClientStats(String userId, String clientId) async {
    try {
      final response = await _client
          .from('invoices')
          .select('total_amount, status')
          .eq('user_id', userId)
          .eq('client_id', clientId);

      final invoices = response as List<dynamic>;
      
      double totalAmount = 0;
      int invoiceCount = invoices.length;
      String lastStatus = 'Nouveau';

      for (var invoice in invoices) {
        totalAmount += (invoice['total_amount'] ?? 0).toDouble();
        final status = invoice['status'] as String?;
        if (status == 'overdue') {
          lastStatus = 'En retard';
        } else if (status == 'sent' && lastStatus != 'En retard') {
          lastStatus = 'En attente';
        } else if (status == 'paid' && lastStatus == 'Nouveau') {
          lastStatus = 'Payé';
        }
      }

      return {
        'totalAmount': totalAmount,
        'invoiceCount': invoiceCount,
        'lastStatus': invoiceCount == 0 ? 'Nouveau' : lastStatus,
      };
    } catch (e) {
      print('❌ Erreur calcul stats client : $e');
      return {
        'totalAmount': 0.0,
        'invoiceCount': 0,
        'lastStatus': 'Nouveau',
      };
    }
  }

  // ==========================================
  // RÉCUPÉRER TOUTES LES FACTURES
  // ==========================================
  static Future<List<Map<String, dynamic>>> getAllInvoices(String userId) async {
    try {
      final response = await _client
          .from('invoices')
          .select('*, clients(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération factures : $e');
      return [];
    }
  }

  // ==========================================
  // CRÉER UNE FACTURE
  // ==========================================
   // ==========================================
  // CRÉER UNE FACTURE
  // ==========================================
  static Future<String?> createInvoice({
    required String userId,
    required String clientId,
    required String invoiceNumber,
    required DateTime issueDate,
    DateTime? dueDate,
    String? notes,
    required double subtotal,
    required double tvaAmount,
    required double totalAmount,
    String status = 'sent', // ← NOUVEAU PARAMÈTRE (défaut: 'sent' = envoyée)
  }) async {
    try {
      final response = await _client
          .from('invoices')
          .insert({
            'user_id': userId,
            'client_id': clientId,
            'invoice_number': invoiceNumber,
            'issue_date': issueDate.toIso8601String().split('T')[0],
            'due_date': dueDate?.toIso8601String().split('T')[0],
            'notes': notes,
            'subtotal': subtotal,
            'tva_amount': tvaAmount,
            'total_amount': totalAmount,
            'status': status, // ← Utilise le paramètre status
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      print('❌ Erreur création facture : $e');
      return null;
    }
  }

  // ==========================================
  // CRÉER LES LIGNES DE FACTURE
  // ==========================================
  static Future<void> createInvoiceItems({
    required String invoiceId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final itemsToInsert = items.map((item) => {
        'invoice_id': invoiceId,
        'description': item['description'],
        'quantity': item['quantity'],
        'unit_price': item['unitPrice'],
        'total_price': item['totalPrice'],
      }).toList();

      await _client.from('invoice_items').insert(itemsToInsert);
    } catch (e) {
      print('❌ Erreur création lignes facture : $e');
      throw Exception('Erreur lors de la sauvegarde des articles');
    }
  }

  // ==========================================
  // GÉNÉRER LE PROCHAIN NUMÉRO DE FACTURE
  // ==========================================
  static Future<String> getNextInvoiceNumber(String userId) async {
    try {
      final year = DateTime.now().year;
      final response = await _client
          .from('invoices')
          .select('invoice_number')
          .eq('user_id', userId)
          .like('invoice_number', 'FAC-$year-%')
          .order('invoice_number', ascending: false)
          .limit(1);

      final invoices = response as List<dynamic>;
      
      if (invoices.isEmpty) {
        return 'FAC-$year-001';
      }

      final lastNumber = invoices[0]['invoice_number'] as String;
      final parts = lastNumber.split('-');
      final lastSeq = int.parse(parts[2]);
      final nextSeq = (lastSeq + 1).toString().padLeft(3, '0');

      return 'FAC-$year-$nextSeq';
    } catch (e) {
      print('❌ Erreur génération numéro : $e');
      return 'FAC-${DateTime.now().year}-001';
    }
  }
    // ==========================================
  // RÉCUPÉRER TOUS LES SERVICES DE L'UTILISATEUR
  // ==========================================
  static Future<List<Map<String, dynamic>>> getAllServices(String userId) async {
    try {
      final response = await _client
          .from('services')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération services : $e');
      return [];
    }
  }

  // ==========================================
  // CRÉER UN SERVICE
  // ==========================================
  static Future<void> createService({
    required String userId,
    required String name,
    String? description,
    required double unitPrice,
  }) async {
    try {
      await _client.from('services').insert({
        'user_id': userId,
        'name': name,
        'description': description,
        'unit_price': unitPrice,
      });
      print('✅ Service créé');
    } catch (e) {
      print('❌ Erreur création service : $e');
      throw Exception('Erreur lors de la sauvegarde du service');
    }
  }

  // ==========================================
  // SUPPRIMER UN SERVICE
  // ==========================================
  static Future<void> deleteService(String serviceId) async {
    try {
      await _client.from('services').delete().eq('id', serviceId);
      print('✅ Service supprimé');
    } catch (e) {
      print('❌ Erreur suppression service : $e');
      throw Exception('Erreur lors de la suppression');
    }
  }
    // ==========================================
  // METTRE À JOUR LE STATUT D'UNE FACTURE
  // ==========================================
  static Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      await _client
          .from('invoices')
          .update({'status': status})
          .eq('id', invoiceId);
      print('✅ Statut mis à jour : $status');
    } catch (e) {
      print('❌ Erreur mise à jour statut : $e');
      throw Exception('Erreur lors de la mise à jour');
    }
  }
}